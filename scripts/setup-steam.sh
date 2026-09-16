#!/usr/bin/env bash
#
# ASLM — camada de jogos estilo Bazzite: Steam + Lutris + GameMode.
# Funciona com as distros suportadas (Arch, Ubuntu, Debian, Fedora, Alpine...).
#
# NOTA: em ARM64 o Steam roda via box64 (lento, titulos leves apenas).
#       Em x86_64 roda nativamente.
#
# Uso:
#   bash scripts/setup-steam.sh setup [distro]    # prepara X11 + Vulkan + Steam
#   bash scripts/setup-steam.sh start [distro]    # abre o Steam (janela X11)
#   bash scripts/setup-steam.sh stop  [distro]    # encerra Steam/X11
set -euo pipefail

ASLM_GREEN='\033[1;32m'; ASLM_YEL='\033[1;33m'; ASLM_NC='\033[0m'
say()  { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }
warn() { echo -e "${ASLM_YEL}[ASLM] aviso:${ASLM_NC} $*"; }

ARCH=$(uname -m)
ACTION="${1:-setup}"
DISTRO="${2:-${ASLM_DISTRO:-archlinux}}"

login() { proot-distro login "${DISTRO}" -- "$@"; }
is_arm() { [ "${ARCH}" = "aarch64" ] || [ "${ARCH}" = "arm64" ]; }

# --- instalacao de pacotes por familia ---------------------------------------
install_common() {
  case "${DISTRO}" in
    archlinux|manjaro)
      login bash -c 'pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        xorg-server-xephyr xorg-xrandr xorg-xwayland mesa vulkan-intel vulkan-radeon \
        lutris gamemode wine flatpak xdg-utils gcc git curl wget' ;;
    ubuntu|debian)
      login bash -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        xserver-xorg x11-xserver-utils xwayland mesa-utils mesa-vulkan-drivers \
        libgl1-mesa-dri lutris gamemode wine flatpak xdg-utils gcc git curl wget' ;;
    fedora|rockylinux|almalinux)
      login bash -c 'dnf -y install \
        xorg-x11-server-Xephyr xorg-x11-utils xorg-x11-server-Xwayland \
        mesa-vulkan-drivers mesa-dri-drivers vulkan-loader \
        lutris gamemode wine flatpak xdg-utils gcc git curl wget' ;;
    opensuse-tumbleweed)
      login bash -c 'zypper --non-interactive install \
        xorg-x11-server-Xephyr xwayland Mesa-vulkan-drivers \
        lutris gamemode wine flatpak gcc git curl wget' ;;
    alpine)
      login sh -c 'apk update && apk add \
        xwayland mesa-dri-gallium vulkan-loader \
        lutris gamemode wine flatpak gcc git curl wget' ;;
    *)
      warn "Familia de distro desconhecida: ${DISTRO}" ;;
  esac
}

setup_x11_android() {
  say "Instalando X11/video/audio no Termux (termux-x11, VirGL, PulseAudio)..."
  pkg install -y termux-x11-nightly wayland xwayland virglrenderer-android pulseaudio
}

install_box64() {
  say "Instalando box64 (emulador x86_64 -> ARM) para o Steam..."
  login bash -c '
    curl -LsSf https://github.com/ptitSeb/box64/releases/download/v0.3.3/box64-v0.3.3-Linux-aarch64.tar.gz -o /tmp/box64.tgz
    tar -xzf /tmp/box64.tgz -C /tmp
    install -m755 /tmp/box64/box64 /usr/local/bin/
    echo "box64.log = 1" > /etc/box64.box64rc'
}

install_steam_native() {
  case "${DISTRO}" in
    archlinux|manjaro)
      login bash -c '
        sed -i "s/^#\[multilib\]/[multilib]/" /etc/pacman.conf
        sed -i "/^\[multilib\]/,+1 s/^#//" /etc/pacman.conf
        pacman -Sy --noconfirm steam' ;;
    ubuntu)
      login bash -c 'add-apt-repository -y multiverse 2>/dev/null || true; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y steam-installer' ;;
    debian)
      login bash -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common; \
        add-apt-repository -y contrib; add-apt-repository -y non-free; \
        apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y steam-installer' ;;
    fedora|rockylinux|almalinux)
      login bash -c 'dnf -y install \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" || true; \
        dnf -y install steam' ;;
    opensuse-tumbleweed)
      login bash -c 'zypper --non-interactive addrepo -cfp 90 \
        https://download.opensuse.org/repositories/games/openSUSE_Tumbleweed/ games; \
        zypper --non-interactive --gpg-auto-import-keys refresh; \
        zypper --non-interactive install steam' ;;
    *)
      warn "Steam nativo nao mapeado para ${DISTRO}; tentando Flatpak."; return 1 ;;
  esac
}

install_steam_flatpak() {
  say "Instalando Steam via Flatpak..."
  login bash -c '
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub com.valvesoftware.Steam'
}

install_steam() {
  if is_arm; then
    install_box64
    install_steam_flatpak || warn "Flatpak do Steam falhou."
    warn "Steam (box64) instalado, mas JOGOS triplo-A nao vao rodar em ARM64."
  else
    install_steam_native || install_steam_flatpak || warn "Nao foi possivel instalar o Steam."
  fi
}

setup() {
  say "Distro: ${DISTRO} | Arquitetura: ${ARCH}"
  if is_arm; then warn "ARM64: Steam rodara via box64 (experimental)."; fi
  setup_x11_android
  install_common
  install_steam
  say "Ambiente estilo Bazzite pronto! Rode: bash scripts/setup-steam.sh start ${DISTRO}"
}

start() {
  say "Subindo termux-x11 + pulseaudio..."
  termux-x11 -ac -br &
  sleep 2
  pulseaudio --start 2>/dev/null || true
  say "Iniciando o Steam no display :0 de ${DISTRO}..."
  DISPLAY=:0 login sh -c 'steam || flatpak run com.valvesoftware.Steam' \
    || warn "Steam encerrou com erro — veja docs/compatibilidade.md"
}

stop() {
  say "Encerrando Steam/X11..."
  login bash -c 'pkill -f steam; pkill -f steamwebhelper; pkill -f lutris' 2>/dev/null || true
  killall termux-x11 2>/dev/null || true
  say "Feito."
}

case "${ACTION}" in
  setup)  setup ;;
  start)  start ;;
  stop)   stop ;;
  *) echo "Uso: $0 {setup|start|stop} [distro]" ;;
esac
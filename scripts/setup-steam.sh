#!/usr/bin/env bash
#
# ASLM — camada de jogos estilo Bazzite: Steam + Lutris + GameMode no Arch proot.
#
# NOTA: em ARM64 o Steam roda via box64 (lento, títulos leves apenas).
#       Em x86_64 roda nativamente (multilib).
#
# Uso:
#   bash scripts/setup-steam.sh setup      # prepara X11 + Vulkan + Steam
#   bash scripts/setup-steam.sh start      # abre o Steam (com janela X11)
#   bash scripts/setup-steam.sh stop       # encerra Steam/Xwayland
set -euo pipefail

ASLM_GREEN='\033[1;32m'; ASLM_YEL='\033[1;33m'; ASLM_NC='\033[0m'
say() { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }
warn() { echo -e "${ASLM_YEL}[ASLM] aviso:${ASLM_NC} $*"; }

ARCH=$(uname -m)
login() { proot-distro login archlinux -- "$@"; }

is_arm() {
  [ "${ARCH}" = "aarch64" ] || [ "${ARCH}" = "arm64" ]
}

setup_arch_packages() {
  say "Instalando pacotes compartilhados dentro do Arch..."
  login bash -c '
    pacman -Syu --noconfirm
    pacman -S --noconfirm --needed \
      xorg-server-xephyr xorg-xrandr xorg-xwayland \
      mesa vulkan-intel vulkan-radeon \
      lutris gamemode wine \
      flatpak xdg-utils gcc git curl wget
    '
}

setup_x11_android() {
  say "Instalando X11/vídeo/áudio no Termux (termux-x11, VirGL, PulseAudio)..."
  pkg install -y termux-x11-nightly wayland xwayland virglrenderer-android pulseaudio
}

install_box64() {
  say "Instalando box64 (emulador x86_64 -> ARM) para o Steam..."
  login bash -c '
    curl -LsSf https://github.com/ptitSeb/box64/releases/download/v0.3.3/box64-v0.3.3-Linux-aarch64.tar.gz -o /tmp/box64.tgz
    tar -xzf /tmp/box64.tgz -C /tmp
    install -m755 /tmp/box64/box64 /usr/local/bin/
    echo "box64.log = 1" > /etc/box64.box64rc
    '
}

install_steam() {
  if is_arm; then
    install_box64
    say "ARM64: instalando Steam via Flatpak (rodará sob box64)..."
    login bash -c '
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      flatpak install -y flathub com.valvesoftware.Steam
      '
    warn "Steam (box64) instalado, mas JOGOS triplo-A não vão rodar em ARM64."
  else
    say "x86_64: habilitando multilib e instalando Steam nativamente..."
    login bash -c '
      sed -i "s/^#\\[multilib\\]/[multilib]/" /etc/pacman.conf
      sed -i "/^\\[multilib\\]/,+1 s/^#//" /etc/pacman.conf
      pacman -Sy --noconfirm steam
      '
  fi
  say "Steam instalado. Execute: bash scripts/setup-steam.sh start"
}

setup() {
  say "Arquitetura detectada: ${ARCH}"
  if is_arm; then warn "ARM64: Steam rodará via box64 (experimental)."; fi

  setup_x11_android
  setup_arch_packages
  install_steam
  say "Ambiente estilo Bazzite pronto!"
}

start() {
  say "Subindo termux-x11 + pulseaudio..."
  termux-x11 -ac -br &
  sleep 2
  pulseaudio --start 2>/dev/null || true

  say "Iniciando o Steam no display :0 do Arch..."
  DISPLAY=:0 login bash -c 'steam' || warn "Steam encerrou com erro — veja docs/compatibilidade.md"
}

stop() {
  say "Encerrando Steam/X11..."
  login bash -c 'pkill -f steam; pkill -f steamwebhelper; pkill -f lutris' 2>/dev/null || true
  killall termux-x11 2>/dev/null || true
  say "Feito."
}

case "${1:-setup}" in
  setup)                setup ;;
  install-steam-only)   install_steam ;;
  start)                start ;;
  stop)                 stop ;;
  *) echo "Uso: $0 {setup|install-steam-only|start|stop}" ;;
esac
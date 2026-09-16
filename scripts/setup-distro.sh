#!/usr/bin/env bash
#
# ASLM — gerenciador multi-distro (GNU/Linux sobre o Android via proot-distro).
#
# Uso:
#   bash scripts/setup-distro.sh list                 # lista distros suportadas
#   bash scripts/setup-distro.sh install <distro>     # instala + sincroniza
#   bash scripts/setup-distro.sh shell <distro>       # abre o shell
#   bash scripts/setup-distro.sh remove <distro>      # remove
#
# Distros: archlinux, manjaro, ubuntu, debian, fedora, rocky, alma, alpine,
#          void, opensuse, bazzite (perfil gamer sobre Fedora)
set -euo pipefail

ASLM_GREEN='\033[1;32m'; ASLM_YEL='\033[1;33m'; ASLM_RED='\033[1;31m'; ASLM_NC='\033[0m'
say()  { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }
warn() { echo -e "${ASLM_YEL}[ASLM] aviso:${ASLM_NC} $*"; }
fail() { echo -e "${ASLM_RED}[ASLM] ERRO:${ASLM_NC} $*"; exit 1; }

SUPPORTED="archlinux manjaro ubuntu debian fedora rocky alma alpine void opensuse bazzite"

require_proot() {
  command -v proot-distro >/dev/null 2>&1 || fail "proot-distro nao encontrado. Rode scripts/bootstrap.sh primeiro."
}

# Converte nomes amigaveis para o nome real do proot-distro
map_distro() {
  case "$1" in
    rocky)    echo "rockylinux" ;;
    alma)     echo "almalinux" ;;
    opensuse) echo "opensuse-tumbleweed" ;;
    bazzite)  echo "fedora" ;;      # perfil gamer: usa Fedora como base
    *)        echo "$1" ;;
  esac
}

is_supported() {
  local d
  for d in ${SUPPORTED}; do [ "$d" = "$1" ] && return 0; done
  return 1
}

is_installed() {
  proot-distro login "$1" -- true >/dev/null 2>&1
}

sync_packages() {
  local d="$1"
  say "Sincronizando pacotes de ${d}..."
  case "${d}" in
    archlinux|manjaro)
      proot-distro login "${d}" -- pacman -Syu --noconfirm ;;
    ubuntu|debian)
      proot-distro login "${d}" -- bash -c \
        'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y' ;;
    fedora|rockylinux|almalinux|opensuse-tumbleweed)
      proot-distro login "${d}" -- dnf -y upgrade ;;
    alpine)
      proot-distro login "${d}" -- sh -c 'apk update && apk upgrade' ;;
    void)
      proot-distro login "${d}" -- xbps-install -Syu || true ;;
    *)
      warn "Sem sincronizacao automatica para ${d}." ;;
  esac
}

install_bazzite_profile() {
  local base
  base=$(map_distro bazzite)
  say "Perfil 'estilo Bazzite' = Fedora + stack de jogos (Steam/Lutris/GameMode/MangoHud)."
  warn "Bazzite real e uma imagem imutavel (Fedora Atomic) e NAO roda via proot-distro;"
  warn "este perfil reproduz a experiencia de jogos, nao o sistema imutavel."
  install_distro "fedora"
  say "Instalando stack de jogos no Fedora (RPM Fusion)..."
  proot-distro login "${base}" -- bash -c '
    dnf -y install \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" || true
    dnf -y install steam lutris gamemode mangohud || true
  ' || warn "Alguns pacotes podem ter falhado; rode 'bash scripts/setup-steam.sh' depois."
}

install_distro() {
  local name="$1" real
  real=$(map_distro "${name}")
  if is_installed "${real}"; then
    say "${real} ja esta instalada."
  else
    say "Instalando ${real} via proot-distro (baixando rootfs)..."
    proot-distro install "${real}" || fail "falha ao instalar ${real}."
  fi
  sync_packages "${real}"
}

open_shell() {
  local real; real=$(map_distro "$1")
  say "Entrando em ${real} (digite 'exit' para voltar ao Android)."
  proot-distro login "${real}"
}

remove_distro() {
  local real; real=$(map_distro "$1")
  echo -e "${ASLM_YEL}[ASLM] Removendo ${real} (isso apaga TUDO dele).${ASLM_NC}"
  read -rp "Confirma? digite 'sim': " ok
  if [ "${ok}" = "sim" ]; then
    proot-distro remove "${real}"
  else
    say "Cancelado."
  fi
}

list_distros() {
  say "Distros suportadas pelo ASLM:"
  echo "  ${SUPPORTED}"
  echo
  say "Distros com rootfs disponiveis no proot-distro upstream:"
  proot-distro list 2>/dev/null || warn "rode scripts/bootstrap.sh para instalar o proot-distro."
}

action="${1:-list}"
case "${action}" in
  list) list_distros ;;
  install)
    [ $# -ge 2 ] || fail "uso: $0 install <distro>"
    is_supported "$2" || fail "distro nao suportada: $2 (veja: $0 list)"
    if [ "$2" = "bazzite" ]; then install_bazzite_profile; else install_distro "$2"; fi
    say "Pronto. Abra com: bash scripts/setup-distro.sh shell $2"
    ;;
  shell)
    [ $# -ge 2 ] || fail "uso: $0 shell <distro>"
    open_shell "$2"
    ;;
  remove)
    [ $# -ge 2 ] || fail "uso: $0 remove <distro>"
    remove_distro "$2"
    ;;
  *) fail "uso: $0 {list|install|shell|remove} [distro]" ;;
esac
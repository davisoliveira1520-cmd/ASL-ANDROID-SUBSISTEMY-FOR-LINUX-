#!/usr/bin/env bash
#
# ASLM — instala/gerencia o Arch Linux por cima do Android (proot-distro).
#
# Uso:
#   bash scripts/setup-arch.sh install          # instala Arch
#   bash scripts/setup-arch.sh shell            # abre o shell
#   bash scripts/setup-arch.sh remove          # remove (apaga tudo)
set -euo pipefail

ASLM_GREEN='\033[1;32m'; ASLM_YEL='\033[1;33m'; ASLM_NC='\033[0m'
say() { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }

command -v proot-distro >/dev/null 2>&1 || { echo "rode scripts/bootstrap.sh primeiro"; exit 1; }

case "${1:-shell}" in
  install)
    say "Instalando Arch Linux (archlinux/linux) dentro do Android..."
    proot-distro install archlinux
    say "Sincronizando: pacman -Syu"
    proot-distro login archlinux -- pacman -Syu --noconfirm
    say "OK. Rode: bash scripts/setup-arch.sh shell"
    ;;
  shell)
    say "Entrando no Arch Linux (digite 'exit' para voltar ao Android)."
    proot-distro login archlinux
    ;;
  remove)
    echo -e "${ASLM_YEL}[ASLM] Removendo a distro archlinux (isso apaga TUDO dela).${ASLM_NC}"
    read -rp "Confirma? digite 'sim': " ok
    if [ "$ok" = "sim" ]; then
      proot-distro remove archlinux
    else
      say "Cancelado."
    fi
    ;;
  *)
    echo "Uso: $0 {install|shell|remove}"
    ;;
esac
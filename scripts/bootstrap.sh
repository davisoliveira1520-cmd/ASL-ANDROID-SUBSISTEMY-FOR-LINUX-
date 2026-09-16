#!/usr/bin/env bash
#
# ASLM — bootstrap
# Prepara o Android (via Termux) para rodar GNU/Linux.
#
# Uso:
#   bash scripts/bootstrap.sh
set -euo pipefail

ASLM_GREEN='\033[1;32m'
ASLM_RED='\033[1;31m'
ASLM_NC='\033[0m'

say()  { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }
fail() { echo -e "${ASLM_RED}[ASLM] ERRO:${ASLM_NC} $*"; exit 1; }

# --- Sanidade ----------------------------------------------------------------
command -v pkg >/dev/null 2>&1 || fail "execute isto dentro do Termux (pkg nao encontrado)."
command -v proot-distro >/dev/null 2>&1 || {
  say "Instalando proot-distro..."
  pkg update -y
  pkg install -y proot-distro
}

# --- Instala a distro Arch Linux ----------------------------------------------
if ! proot-distro list | grep -q archlinux; then
  say "Instalando Arch Linux (arquivos baixados do repositório archlinux/linux)..."
  proot-distro install archlinux || fail "falha ao instalar a distro archlinux."
fi

say "Sincronizando pacotes dentro do Arch (pacman -Syu)..."
proot-distro login archlinux -- pacman -Syu --noconfirm || fail "falha no pacman -Syu."

# --- Atalho para o dia a dia ----------------------------------------------------
setup_alias() {
  local rc="${HOME}/.bashrc"
  if [ -f "${rc}" ] && ! grep -q '^alias aslm=' "${rc}"; then
    printf '\nalias aslm="proot-distro login archlinux"\n' >> "${rc}"
    say 'Criado o atalho `aslm` em ~/.bashrc'
  else
    say 'Atalho `aslm` já presente (ou sem .bashrc).'
  fi
}
setup_alias

say "Pronto! Use: proot-distro login archlinux  (ou o atalho: aslm)"
say "Exemplos: aslm -- pacman -S neofetch && aslm -- neofetch"
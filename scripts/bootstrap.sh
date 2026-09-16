#!/usr/bin/env bash
#
# ASLM — bootstrap
# Prepara o Android (via Termux) para rodar GNU/Linux e instala uma distro.
#
# Uso:
#   bash scripts/bootstrap.sh                # instala o Arch Linux (padrao)
#   bash scripts/bootstrap.sh ubuntu         # instala Ubuntu
#   bash scripts/bootstrap.sh bazzite        # perfil gamer (Fedora + jogos)
set -euo pipefail

ASLM_GREEN='\033[1;32m'; ASLM_YEL='\033[1;33m'; ASLM_RED='\033[1;31m'; ASLM_NC='\033[0m'
say()  { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }
warn() { echo -e "${ASLM_YEL}[ASLM] aviso:${ASLM_NC} $*"; }
fail() { echo -e "${ASLM_RED}[ASLM] ERRO:${ASLM_NC} $*"; exit 1; }

DISTRO="${1:-archlinux}"

# --- Sanidade ----------------------------------------------------------------
command -v pkg >/dev/null 2>&1 || fail "execute isto dentro do Termux (pkg nao encontrado)."
command -v proot-distro >/dev/null 2>&1 || {
  say "Instalando proot-distro..."
  pkg update -y
  pkg install -y proot-distro
}

# --- Instala a distro escolhida via setup-distro.sh --------------------------
ASLM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
say "ASLM: instalando distro '${DISTRO}'..."
bash "${ASLM_DIR}/setup-distro.sh" install "${DISTRO}"

# --- Atalho unico para o dia a dia -------------------------------------------
setup_alias() {
  local rc="${HOME}/.bashrc"
  if [ -f "${rc}" ] && ! grep -q '^aslm()' "${rc}"; then
    {
      echo ''
      echo 'aslm() { proot-distro login "${1:-'"${DISTRO}"'}" "${@:2}"; }'
    } >> "${rc}"
    say "Criada a funcao 'aslm' em ~/.bashrc (usa ${DISTRO} por padrao)."
  else
    say "Funcao 'aslm' ja presente (ou sem .bashrc)."
  fi
}
setup_alias

say "Tudo pronto!"
say "  aslm                 # entra em ${DISTRO}"
say "  aslm ubuntu          # entra no Ubuntu (se instalado)"
say "  aslm -- pacman -S neofetch"
say "  bash scripts/setup-steam.sh setup   # camada de jogos (estilo Bazzite)"
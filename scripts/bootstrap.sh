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

# --- Instala o comando 'aslm' (CLI estilo WSL) no PATH ----------------------
install_aslm_cli() {
  local dest="${PREFIX:-/data/data/com.termux/files/usr}/bin/aslm"
  install -m755 "${ASLM_DIR}/aslm" "${dest}"
  say "Comando 'aslm' instalado em ${dest}"
  [ -f "${HOME}/.config/aslm/aslm.conf" ] || {
    mkdir -p "${HOME}/.config/aslm"
    printf 'ASLM_DISTRO="%s"\n' "${DISTRO}" > "${HOME}/.config/aslm/aslm.conf"
    say "Config padrão criada: ${HOME}/.config/aslm/aslm.conf (distro=${DISTRO})"
  }
}
install_aslm_cli

say "Tudo pronto!"
say "  aslm                        # abre o shell de ${DISTRO} (estilo wsl)"
say "  aslm --list                 # lista distros"
say "  aslm --install -d ubuntu    # instala Ubuntu"
say "  aslm -d ubuntu lsb_release   # roda comando no Ubuntu"
say "  bash scripts/setup-steam.sh setup   # camada de jogos (estilo Bazzite)"
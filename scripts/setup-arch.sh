#!/usr/bin/env bash
#
# ASLM — compatibilidade: setup-arch.sh agora delega para setup-distro.sh.
#
# Uso:
#   bash scripts/setup-arch.sh install   -> bash scripts/setup-distro.sh install archlinux
#   bash scripts/setup-arch.sh shell     -> bash scripts/setup-distro.sh shell archlinux
#   bash scripts/setup-arch.sh remove    -> bash scripts/setup-distro.sh remove archlinux
set -euo pipefail

ASLM_YEL='\033[1;33m'; ASLM_NC='\033[0m'
echo -e "${ASLM_YEL}[ASLM] nota:${ASLM_NC} setup-arch.sh agora e um atalho para setup-distro.sh (archlinux)."

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${DIR}/setup-distro.sh" "${1:-shell}" archlinux
#!/usr/bin/env bash
#
# ASLM — runner EXPERIMENTAL de macOS via docker-osx (sickcodes).
#
# REQUISITOS (senão, recusa rodar):
#   * Arquitetura x86_64  (celulares ARM64 estão fora)
#   * /dev/kvm disponível (virtualização por hardware)
#   * Android com kernel que exponha /dev/kvm (ex.: emuladores, Chromebooks)
#
# Uso:
#   bash scripts/setup-macos.sh check      # detecta suporte
#   bash scripts/setup-macos.sh pull       # baixa imagem Docker
#   bash scripts/setup-macos.sh run        # inicia o macOS (KVM)
#   bash scripts/setup-macos.sh vnc        # conecta na JDV (tela remota)
set -euo pipefail

ASLM_GREEN='\033[1;32m'; ASLM_RED='\033[1;31m'; ASLM_YEL='\033[1;33m'; ASLM_NC='\033[0m'
say()  { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }
fail() { echo -e "${ASLM_RED}[ASLM] ERRO:${ASLM_NC} $*"; exit 1; }
warn() { echo -e "${ASLM_YEL}[ASLM] aviso:${ASLM_NC} $*"; }

check() {
  local ok=1
  [ "$(uname -m)" = "x86_64" ] || { warn "Arquitetura é $(uname -m) — macOS só existe para x86_64."; ok=0; }
  [ -e /dev/kvm ] || { warn "/dev/kvm não existe — sem virtualização por hardware."; ok=0; }
  command -v docker >/dev/null 2>&1 || { warn "docker não encontrado (num Android, use proot Docker ou um host Linux/AOSP)."; ok=0; }
  if [ "$ok" = "1" ]; then say "Suporte OK: x86_64 + /dev/kvm + docker."; else fail "Aparelho não atende os requisitos."; fi
}

pull() {
  check
  say "Baixando imagem docker-osx (macOS Catalina)..."
  docker pull sickcodes/docker-osx:auto
}

run() {
  check
  local port=50922
  say "Iniciando macOS na porta ${port} (VNC: localhost:${port})..."
  docker run -it --device /dev/kvm -p "${port}:50922" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0}" \
    sickcodes/docker-osx:auto
}

vnc() {
  say "Conectando na tela VNC do macOS (porta 50922)..."
  if command -v vncviewer >/dev/null 2>&1; then
    vncviewer localhost:50922
  else
    warn "Instale um cliente VNC (ex.: bVNC no F-Droid) e conecte em localhost:50922"
  fi
}

case "${1:-check}" in
  check) check ;;
  pull)  pull ;;
  run)   run ;;
  vnc)   vnc ;;
  *) echo "Uso: $0 {check|pull|run|vnc}" ;;
esac
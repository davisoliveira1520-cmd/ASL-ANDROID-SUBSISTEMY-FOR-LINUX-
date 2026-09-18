#!/usr/bin/env bash
#
# ASLM — modo "Linux no kernel do Android" (boot switch via kexec-hardboot)
#
# IDEIA: em vez de dual boot com outro kernel, este script usa o MESMO kernel
# que o Android ja carrega. Ele executa um kexec: carrega o kernel atual +
# um initramfs ASLM e pula para dentro dele "por cima" do Android — o Linux
# roda no kernel do Android. Android permanece instalado; um simples reboot
# volta para ele. Isto NÃO é um boot persistente/duplo em partição.
#
# ⚠️ EXPERIMENTAL e dependente do aparelho:
#   - Requer root (Magisk/KernelSU).
#   - Requer kernel com CONFIG_KEXEC (e, idealmente, suporte a kexec -l de
#     imagens; muitos kernels de Android vêm SEM /dev/kexec).
#   - Em kernels de fábrica geralmente é preciso um kernel com patch
#     MultiROM/kexec-hardboot. Verifique com: bash scripts/setup-kexec.sh check
#
# Uso:
#   bash scripts/setup-kexec.sh check    # diagnostica o aparelho (leia!)
#   bash scripts/setup-kexec.sh setup    # prepara rootfs GNU + initramfs
#   bash scripts/setup-kexec.sh boot     # pula para o Linux (volte com reboot)
set -euo pipefail

ASLM_GREEN='\033[1;32m'; ASLM_YEL='\033[1;33m'; ASLM_RED='\033[1;31m'; ASLM_NC='\033[0m'
say()  { echo -e "${ASLM_GREEN}[ASLM]${ASLM_NC} $*"; }
warn() { echo -e "${ASLM_YEL}[ASLM] aviso:${ASLM_NC} $*"; }
fail() { echo -e "${ASLM_RED}[ASLM] ERRO:${ASLM_NC} $*"; exit 1; }

KEXEC_DIR="/data/local/aslm"
ROOTFS="${KEXEC_DIR}/linux"
INITRAMFS="${KEXEC_DIR}/initramfs"
KERNEL_IMG="${KEXEC_DIR}/kernel"
TMUX_ROOTFS="${HOME}/.local/share/proot-distro/installed-rootfs"

require_root() {
  [ "$(id -u)" = "0" ] || fail "precisa de root (su/sudo/Magisk) para este modo."
}

# ---------------------------------------------------------------------------
check() {
  say "Diagnóstico do aparelho para o modo kexec-hardboot:"
  echo

  [ "$(id -u)" = "0" ] && say "  root: OK ✓" || warn "  root: NÃO (precisa de root!)"

  if [ -e /dev/kexec ]; then
    say "  /dev/kexec: OK ✓"
  else
    warn "  /dev/kexec: NAO existe (kernel de fábrica costuma vir sem CONFIG_KEXEC)"
  fi

  if [ -r /proc/config.gz ]; then
    zcat /proc/config.gz 2>/dev/null | grep -E '^CONFIG_KEXEC' | sed 's/^/    /'
  else
    warn "  /proc/config.gz indisponível (não dá para confirmar CONFIG_KEXEC)"
  fi

  local selinux
  selinux=$(getenforce 2>/dev/null || echo "n/a")
  case "${selinux}" in
    Permissive|Disabled) say "  SELinux: ${selinux} (ok) ✓" ;;
    Enforcing) warn "  SELinux: Enforcing (pode bloquear kexec; teste com 'setenforce 0')" ;;
    *) warn "  SELinux: ${selinux}" ;;
  esac

  if command -v kexec >/dev/null 2>&1; then
    say "  kexec-tools: OK ✓"
  else
    warn "  kexec-tools: n/a (pkg install kexec-tools)"
  fi

  if [ -f "${KERNEL_IMG}" ]; then say "  kernel ASLM: OK ✓"; else warn "  kernel ASLM: ausente (cheque docs/modo-kernel-nativo.md)"; fi

  echo
  say "Conclusão: se algo acima estiver em vermelho/aviso, o melhor caminho é o"
  say "modo chroot-nativo (dentro do Android) ou continuar no proot."
}

# ---------------------------------------------------------------------------
prepare_rootfs() {
  if [ -d "${ROOTFS}" ]; then
    say "rootfs GNU já existente em ${ROOTFS}"
    return
  fi
  # reaproveita o rootfs do proot-distro (archlinux) se existir
  if [ -d "${TMUX_ROOTFS}/archlinux" ]; then
    say "Usando rootfs do proot-distro (archlinux)..."
    cp -a "${TMUX_ROOTFS}/archlinux" "${ROOTFS}"
  else
    say "Instalando (ou localizando) o archlinux via proot-distro..."
    command -v proot-distro >/dev/null 2>&1 && proot-distro install archlinux || true
    [ -d "${TMUX_ROOTFS}/archlinux" ] || fail "rootfs não encontrado. Rode scripts/bootstrap.sh primeiro."
    cp -a "${TMUX_ROOTFS}/archlinux" "${ROOTFS}"
  fi
}

build_initramfs() {
  local busybox
  busybox=$(command -v busybox || echo "")
  if [ -z "${busybox}" ]; then
    warn "BusyBox não encontrado — initramfs será criado vazio (sem /init)."
    : > "${INITRAMFS}/placeholder"
    return
  fi
  mkdir -p "${INITRAMFS}/initramfs-root/"
  cp "${busybox}" "${INITRAMFS}/initramfs-root/busybox"
  cat > "${INITRAMFS}/initramfs-root/init" <<'EOF'
#!/bin/busybox sh
# init ASLM — arranca o Linux GNU usando o kernel do Android (kexec-hardboot)
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc none /proc 2>/dev/null
mount -t sysfs none /sys 2>/dev/null
mount -t devtmpfs none /dev 2>/dev/null
mkdir -p /data /newroot
echo "ASLM initramfs: procurando rootfs em /data/local/aslm/linux..."
if mount -o rw /dev/block/by-name/userdata /data 2>/dev/null || mount /data 2>/dev/null; then
    if [ -d /data/local/aslm/linux ]; then
        exec chroot /data/local/aslm/linux /bin/bash -l
    fi
fi
echo "ASLM: rootfs nao encontrado. Abrindo shell de rescate."
exec /bin/busybox sh
EOF
  chmod +x "${INITRAMFS}/initramfs-root/init"
  ( cd "${INITRAMFS}/initramfs-root" && find . -depth | cpio -o -H newc 2>/dev/null | gzip -9 > "${INITRAMFS}/initrd.gz" )
  say "initramfs gerado: ${INITRAMFS}/initrd.gz"
}

setup() {
  require_root
  require_kexec_tools
  mkdir -p "${KEXEC_DIR}" "${INITRAMFS}"
  prepare_rootfs
  build_initramfs
  say "Setup pronto. Ainda falta o 'kernel ASLM' (veja docs):"
  say "  kernel esperado em: ${KERNEL_IMG}"
  say "Depois, rode: bash scripts/setup-kexec.sh boot"
}

# ---------------------------------------------------------------------------
require_kexec_tools() {
  command -v kexec >/dev/null 2>&1 || {
    say "Instalando kexec-tools no Termux..."
    pkg install -y kexec-tools || fail "nao consegui instalar kexec-tools."
  }
}

boot() {
  require_root
  [ -f "${KERNEL_IMG}" ] || fail "kernel ASLM ausente (${KERNEL_IMG}). Veja docs/modo-kernel-nativo.md."
  [ -f "${INITRAMFS}/initrd.gz" ] || fail "initramfs ausente. Rode: bash scripts/setup-kexec.sh setup"

  echo -e "${ASLM_RED}Vai pular para o LINUX agora (Android ficará inativo até reiniciar).${ASLM_NC}"
  read -rp "Digite 'sim' para continuar: " ok
  [ "${ok}" = "sim" ] || { say "Cancelado."; exit 0; }

  local cmdline
  cmdline=$(cat /proc/cmdline 2>/dev/null || echo "")
  say "Carregando kernel + initramfs via kexec..."
  kexec -l "${KERNEL_IMG}" --initrd "${INITRAMFS}/initrd.gz" --append "${cmdline}" \
    || fail "kexec -l falhou (veja o diagnóstico: bash scripts/setup-kexec.sh check)"

  say "Pulando para o Linux (o kernel do Android continua o mesmo) — reboot volta ao Android."
  sync
  kexec -e
}

case "${1:-check}" in
  check) check ;;
  setup) setup ;;
  boot)  boot ;;
  *) echo "Uso: $0 {check|setup|boot}" ;;
esac
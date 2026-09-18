# Modo Kernel Nativo (kexec-hardboot) — EXPERIMENTAL

O modo padrão do ASLM (proot) roda GNU/Linux **em userspace traduzido**.
Este modo tenta ir mais longe: **pular para dentro do Linux usando o MESMO
kernel do Android** (kexec), sem apagar o Android.

---

## Como funciona (resumo)

```
[Boot normal do Android]
        │
        ▼
[kexec-hardboot → ASLM initramfs + rootfs GNU/Linux]
        │
        ▼
[Linux roda no kernel do Android (nativo!)]
        │  (reboot → volta ao Android)
        ▼
[Boot normal do Android novamente]
```

1. O Android liga normal (kernel + drivers + tudo).
2. Um script (como `setup-kexec.sh boot`) carrega o kernel atual + um
   **initramfs ASLM** via `kexec -l` e em seguida `kexec -e` (reboot no
   novo init, com o mesmo kernel).
3. O initramfs monta o rootfs GNU/Linux (que ficou salvo em
   `/data/local/aslm/linux` no armazenamento interno) e o executa.
4. **O Android continua 100% instalado.** Ao reiniciar o aparelho, ele
   inicia o Android normalmente.

---

## O que é (e o que NÃO é)

- **É:** Linux rodando em **velocidade nativa** no mesmo kernel do Android,
  sem duplicar partição, com o Android instalado e recuperável.
- **NÃO é:** Dual boot persistente com menu de boot (isso exige patches no
  kernel/gerenciador de boot — MultiROM, recoveries customizados, etc.).
  Este script é um gatilho único via `kexec`; ele sobrescreve o kernel em
  memória uma única vez. O próximo boot volta ao Android normal.

---

## Requisitos

1. **Root** (Magisk, KernelSU ou rooteamento equivalente).
2. **Kernel com CONFIG_KEXEC** (suporte a `kexec` em /dev).
3. **`kexec-tools`** (no Termux: `pkg install kexec-tools`).
4. Um **initramfs** com `/init` que monte e faça chroot no rootfs GNU.

### Como verificar o aparelho

```sh
bash scripts/setup-kexec.sh check
```

O comando mostra se o aparelho tem: root, `/dev/kexec`, CONFIG_KEXEC,
SELinux permissivo, kexec-tools — e dá o veredito honesto.

> **Se o aparelho não tiver CONFIG_KEXEC**, este modo não funcionará.

---

## Instalação e uso

```sh
# 1. Verifica o aparelho
bash scripts/setup-kexec.sh check

# 2. Prepara rootfs + initramfs (precisa de root)
bash scripts/setup-kexec.sh setup

# 3. Pula para o Linux (vai desligar o Android em memória)
bash scripts/setup-kexec.sh boot

# 4. Volta ao Android
reboot
```

---

## Onde colocar o kernel (CONFIG_KEXEC necessário)

O script espera um kernel (zImage/Image) em:

```
/data/local/aslm/kernel
```

Esse arquivo pode ser:
- O **próprio boot.img** extraído do dispositivo (da partição `/boot`)
- Um kernel compilado **com patch MultiROM/kexec-hardboot** (ideal)

> Em kernels de fábrica de muitos fabricantes (Samsung, Xiaomi, etc.),
> **o CONFIG_KEXEC pode estar desativado ou o `/dev/kexec` pode não existir**.
> O modo mais confiável é usar um kernel custom que inclua o patch
> [MultiROM](https://github.com/nicknassar/multirom-core) ou um equivalente.

---

## Como descobrir a imagem do kernel (estilo Android boot.img)

Se o aparelho estiver rooteado:

```sh
# Localizar a partição de boot
ls /dev/block/by-name/boot
# Copiar o boot.img (adiante,作成 initramfs separado)
dd if=/dev/block/by-name/boot of=/data/local/aslm/boot.img
# Extrair o kernel (pode exigir mkbootimg/unpack_bootimg ou bootimg.sh)
```

> Não é trivial em todos os dispositivos. Verifique compatibilidade do
> aparelho com [android_boot_images_extract](https://github.com/nicknassar/android_boot_images_extract).

---

## Risco

- Se o `kexec` falhar, o aparelho pode travar — basta **segurar o power
  até reiniciar**. O Android não é prejudicado porque nada foi gravado em
  partição.
- Em aparelhos com SELinux enforcing, o `kexec` pode ser bloqueado.
  Pode ser necessário rodar `setenforce 0` (reinicia ao reboot normal).
- Modificar `/proc/cmdline` diretamente do Android é instável em alguns
  kernels (Secure Boot/Verified Boot pode bloquear a execução).

---

## Referências

- [MultiROM](https://github.com/nicknassar/multirom-core) — dual boot
  via kexec-hardboot no Android (Arduino/Android 4-9).
- [kexec documentation](https://www.kernel.org/doc/Documentation/kexec/kexec.txt)
- [LinuxDeploy](https://github.com/meefik/linuxdeploy) — instala Linux
  nativo via chroot (alternativa sem kexec, sem trocar de initramfs).

---

> **Recomendação:** para a maioria dos aparelhos, o **chroot nativo**
> (LinuxDeploy, sem kexec) é mais seguro e confiável que o kexec-hardboot,
> e ainda oferece performance nativa sem trocar de initramfs. O modo
> kexec-hardboot é para quem quer o Linux rodando no lugar do Android em
> memória (temporariamente), com o Android recuperável via reboot.
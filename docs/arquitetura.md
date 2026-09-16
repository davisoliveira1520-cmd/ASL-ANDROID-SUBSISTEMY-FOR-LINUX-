# Arquitetura do ASLM

O ASLM organiza três camadas por cima do Android, sem dual boot e sem substituir o kernel.

```
┌────────────────────────────────────────────────────────────┐
│  APPs Android (Termux, launcher, etc.)                    │
├────────────────────────────────────────────────────────────┤
│  🐧 Camada Linux (proot-distro → Arch/Ubuntu/Debian/Fedora/...)      │
│     ├─ Steam / Lutris / GameMode  (camada estilo Bazzite)  │
│     └─ toolchain, pacotes, shells                          │
├────────────────────────────────────────────────────────────┤
│  🍎 Camada macOS (EXPERIMENTAL: x86_64 + KVM via docker)  │
│     └─ docker-osx (sickcodes)                              │
├────────────────────────────────────────────────────────────┤
│  Android OS  (IME, drivers, HAL, sepolicy)                 │
├────────────────────────────────────────────────────────────┤
│  Kernel Linux (fork Android do archlinux/linux)            │
└────────────────────────────────────────────────────────────┘
```

## Por que "subsystem"?

No WSL, o Windows hospeda um Linux userspace. No ASLM é o inverso: o
**Android hospeda um Linux userspace (Arch)** via `proot`.

- `proot-distro` baixa o rootfs de uma distribuição (Arch, Ubuntu, Debian,
  Fedora, Alpine, ...) da internet.
- Usa `proot` para traduzir chamadas de sistema (sem root — funciona em
  celulares não-roteados).
- O filesystem fica em `~/.local/share/proot-distro/installed-rootfs/`.
- Cada distro é independente: você pode ter Arch + Ubuntu + Fedora lado a lado.

## Camada de jogos (estilo Bazzite)

A ideia vem do [Bazzite](https://github.com/ublue-os/bazzite): um sistema
de jogos "console-like". No ASLM isso vira uma stack dentro do Arch:

- **Box64/Box86**: tradução dinâmica para rodar binários x86/x86_64 em ARM.
- **Mesa (Vulkan/Lavapipe) + VirGL**: renderização por software/GPU forwarding.
- **termux-x11 + Xwayland**: janelas X11 no display :0 do Android.
- **Steam, Lutris e GameMode** para organizar e rodar os jogos.

## Camada macOS (docker-osx)

O [docker-osx](https://github.com/sickcodes/docker-osx) roda macOS dentro
de um container Docker usando **KVM** (virtualização por hardware).

- Exige CPU **x86_64** e `/dev/kvm`.
- Em Android puro (celular ARM64) **não há suporte**.
- Funciona em: PCs/Liutos Android x86_64, Chromebooks com Linux, emuladores
  com KVM, ou servidores físicos Linux.

## Fluxo de instalação

```
bootstrap.sh ──► setup-distro.sh   (Arch/Ubuntu/Debian/Fedora/... no proot)
              └► setup-steam.sh    (X11 + Steam + box64; por distro)
              └► setup-macos.sh    (docker-osx / só x86_64+KVM)
```
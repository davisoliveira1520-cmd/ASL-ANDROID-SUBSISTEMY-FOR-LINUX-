# Arquitetura do ASLM

O ASLM organiza camadas por cima do Android, sem root, sem dual boot e sem substituir o kernel.

```
┌────────────────────────────────────────────────────────────┐
│  APPs Android (Termux, launcher, etc.)                    │
├────────────────────────────────────────────────────────────┤
│  🐧 Camada Linux (proot-distro → Arch/Ubuntu/Debian/Fedora/...)      │
│     ├─ Steam / Lutris / GameMode  (camada estilo Bazzite)  │
│     └─ toolchain, pacotes, shells                          │
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

### Mapa WSL ↔ ASLM

| Conceito | WSL (Windows) | ASLM (Android) |
|---|---|---|
| CLI | `wsl` | `aslm` |
| Instalar distro | `wsl --install -d Ubuntu` | `aslm --install -d ubuntu` |
| Listar | `wsl --list` | `aslm --list` |
| Executar comando | `wsl -d Ubuntu <cmd>` | `aslm -d ubuntu <cmd>` |
| Backup/restauração | `wsl --export / --import` | `aslm --export / --import` |
| Config global | `%UserProfile%\.wslconfig` | `~/.config/aslm/aslm.conf` |
| Motor | WSL1: tradução de syscalls (sem VM) | `proot`: tradução de syscalls (**sem root**) |

O comando `aslm` (em `scripts/aslm`) é instalado no PATH pelo `bootstrap.sh`
e espelha esses subcomandos do WSL sobre o `proot-distro`.

## Camada de jogos (estilo Bazzite)

A ideia vem do [Bazzite](https://github.com/ublue-os/bazzite): um sistema
de jogos "console-like". No ASLM isso vira uma stack dentro do Arch:

- **Box64/Box86**: tradução dinâmica para rodar binários x86/x86_64 em ARM.
- **Mesa (Vulkan/Lavapipe) + VirGL**: renderização por software/GPU forwarding.
- **termux-x11 + Xwayland**: janelas X11 no display :0 do Android.
- **Steam, Lutris e GameMode** para organizar e rodar os jogos.

## Fluxo de instalação

```
bootstrap.sh ──► setup-distro.sh   (Arch/Ubuntu/Debian/Fedora/... no proot)
              └► setup-steam.sh    (X11 + Steam + box64; por distro)
```
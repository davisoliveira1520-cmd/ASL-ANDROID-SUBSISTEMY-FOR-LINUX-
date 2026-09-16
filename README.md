<div align="center">

# ASLM — Android Subsystem for Linux and Mac OS

**Rode GNU/Linux e (experimental) macOS por cima do Android, sem dual boot.**

Roda o kernel **Linux (Arch)** e distribuições **GNU/Linux** em espaço de usuário sobre o Android usando [Termux](https://github.com/termux/termux-app) + [`proot-distro`](https://github.com/termux/proot-distro).
Inclui camada de jogos inspirada no [Bazzite](https://github.com/ublue-os/bazzite) para **Steam**, e um runner **experimental x86_64** para macOS via [docker-osx](https://github.com/sickcodes/docker-osx).

</div>

---

## ⚠️ Aviso honesto (leia antes)

- **Android já é Linux.** O kernel do Android é um fork do Linux. O ASLM não substitui o kernel — ele adiciona distribuições GNU/Linux em cima do Android (a mesma ideia do WSL, mas ao contrário: userspace Linux sobre Android, não sobre Windows).
- **macOS em Android é EXPERIMENTAL e só em x86_64 + KVM.** O [docker-osx](https://github.com/sickcodes/docker-osx) precisa de virtualização por hardware (KVM) e arquitetura x86_64. A maioria dos celulares é ARM64, então **macOS não funciona nessa maioria** — só em tablets/PCS Android x86_64, ou emuladores com KVM. O script `setup-macos.sh` detecta e avisa se seu aparelho não suporta.
- **Steam em ARM64 é lento/experimental.** Jogos nativos não vão rodar bem. O ASLM prepara o ambiente (box64 + X11 + Vulkan-Lavapipe) e deixa você testar títulos leves.

---

## ✨ O que o ASLM faz

| Camada | O que é | Status |
|---|---|---|
| 🐧 **Android Subsystem for Linux** | Arch Linux (e outras distros) rodando em userspace sobre Termux via `proot-distro` | ✅ Estável |
| 🎮 **Steam + Bazzite-like** | Ambiente de jogos (Steam, Lutris, GameMode) dentro do Linux proot, estilo Bazzite | 🧪 Experimental (ARM64) / ✅ x86_64 |
| 🍎 **macOS runner** | Instância de macOS via Docker/KVM (docker-osx) | ⚠️ Só x86_64 + KVM |

Sem dual boot: **tudo roda dentro do Android**, no mesmo aparelho, coexistindo com seus apps.

---

## 📦 Requisitos

- Android **8.0 (Oreo)+** (recomendado 10+)
- [Termux](https://f-droid.org/packages/com.termux/) (instale pela F-Droid, não pelo Play Store — a versão do Play está desatualizada)
- ~4–8 GB de espaço livre (Arch base ~1 GB; Steam+games muito mais)
- Para **macOS**: aparelho/dispositivo **x86_64** com `/dev/kvm` (celulares ARM64 **não** suportam)

---

## 🚀 Instalação rápida

No Termux:

```sh
# 1. Atualize e instale o proot-distro
pkg update && pkg upgrade -y
pkg install -y proot-distro

# 2. Rode o bootstrap do ASLM
curl -fsSL https://raw.githubusercontent.com/davisoliveira1520-cmd/ASL-ANDROID-SUBSISTEMY-FOR-LINUX-/main/scripts/bootstrap.sh | bash
```

Ou clone direto (requer `git` no Termux):

```sh
git clone https://github.com/davisoliveira1520-cmd/ASL-ANDROID-SUBSISTEMY-FOR-LINUX-.git
cd ASLM
bash scripts/bootstrap.sh
```

---

## 📚 Uso

```sh
# Entrar no Linux (Arch) por cima do Android
aslm               # alias: proot-distro login archlinux

# Rodar o Steam (camada estilo Bazzite)
aslm steam &

# Iniciar o runner do macOS (só x86_64 + KVM)
bash scripts/setup-macos.sh run
```

Veja os detalhes em:

- [`docs/arquitetura.md`](docs/arquitetura.md) — como o ASLM funciona por baixo
- [`docs/compatibilidade.md`](docs/compatibilidade.md) — o que roda e o que não roda
- [`scripts/`](scripts/) — scripts de instalação e configuração

---

## 🧱 Créditos & fontes

Este projeto é uma camada de orquestração/documentação sobre código de terceiros:

- 🐧 **Kernel Arch Linux**: [`archlinux/linux`](https://github.com/archlinux/linux)
- 📦 **proot-distro**: [`termux/proot-distro`](https://github.com/termux/proot-distro)
- 🍎 **macOS ISO / docker-osx**: [`sickcodes/docker-osx`](https://github.com/sickcodes/docker-osx)
- 🎮 **Steam / estilo de jogos**: [`ublue-os/bazzite`](https://github.com/ublue-os/bazzite)
- 🐆 **Emulação x86 em ARM**: [`ptitSeb/box64`](https://github.com/ptitSeb/box64) e [`ptitSeb/box86`](https://github.com/ptitSeb/box86)

> **Importante:** respeite as licenças de cada projeto upstream. macOS é software proprietário da Apple — a instalação em hardware não-Apple viola o EULA e é de sua responsabilidade.

---

## 📄 Licença

MIT — veja [LICENSE](LICENSE).

Cada componente upstream mantém sua própria licença.
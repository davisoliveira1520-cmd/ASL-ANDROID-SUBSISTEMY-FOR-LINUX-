<div align="center">

<img src="assets/banner.svg" alt="ASLM — Android Subsystem for Linux and Mac OS" width="100%">

# ASLM — Android Subsystem for Linux and Mac OS

**Rode GNU/Linux e (experimental) macOS por cima do Android, sem dual boot.**

🇧🇷 **Português** · 🇺🇸 [English](README.en.md)

Roda **Arch Linux, Ubuntu, Debian, Fedora, Alpine** e outras distribuições **GNU/Linux** em espaço de usuário sobre o Android usando [Termux](https://github.com/termux/termux-app) + [`proot-distro`](https://github.com/termux/proot-distro).
Inclui um perfil de jogos inspirado no [Bazzite](https://github.com/ublue-os/bazzite) para **Steam**, e um runner **experimental x86_64** para macOS via [docker-osx](https://github.com/sickcodes/docker-osx).

</div>

---

> [!IMPORTANT]
> **Isto NÃO é dual boot.** O ASLM **não mexe na partição de boot** e **não substitui o Android**. Ele apenas **instala distribuições GNU/Linux por cima do Android**, dentro do Termux, convivendo com seus apps normais. Nada é gravado fora das pastas do Termux — para remover, é só apagar a distro ou o app.

---

## ⚠️ Aviso honesto (leia antes)

- **Android já é Linux.** O kernel do Android é um fork do Linux. O ASLM não substitui o kernel — ele adiciona distribuições GNU/Linux em cima do Android (a mesma ideia do WSL, mas ao contrário: userspace Linux sobre Android, não sobre Windows).
- **macOS em Android é EXPERIMENTAL e só em x86_64 + KVM.** O [docker-osx](https://github.com/sickcodes/docker-osx) precisa de virtualização por hardware (KVM) e arquitetura x86_64. A maioria dos celulares é ARM64, então **macOS não funciona nessa maioria** — só em tablets/PCS Android x86_64, ou emuladores com KVM. O script `setup-macos.sh` detecta e avisa se seu aparelho não suporta.
- **Steam em ARM64 é lento/experimental.** Jogos nativos não vão rodar bem. O ASLM prepara o ambiente (box64 + X11 + Vulkan-Lavapipe) e deixa você testar títulos leves.

---

## ✨ O que o ASLM faz

| Camada | O que é | Status |
|---|---|---|
| 🐧 **Android Subsystem for Linux** | Arch, Ubuntu, Debian, Fedora, Alpine e outras via `proot-distro`, sem root | ✅ Estável |
| 🎮 **Steam + Bazzite-like** | Ambiente de jogos (Steam, Lutris, GameMode, MangoHud) no Linux proot | 🧪 Experimental (ARM64) / ✅ x86_64 |
| 🍎 **macOS runner** | Instância de macOS via Docker/KVM (docker-osx) | ⚠️ Só x86_64 + KVM |

Sem dual boot: **tudo roda dentro do Android**, no mesmo aparelho, coexistindo com seus apps.

### 🐧 Distros suportadas

| Nome ASLM | Base | Gerenciador de pacotes |
|---|---|---|
| `archlinux` (padrão) | Arch Linux | `pacman` |
| `manjaro` | Manjaro | `pacman` |
| `ubuntu` | Ubuntu | `apt` |
| `debian` | Debian | `apt` |
| `fedora` | Fedora | `dnf` |
| `rocky` / `alma` | RHEL-compatible | `dnf` |
| `opensuse` | openSUSE Tumbleweed | `zypper` |
| `alpine` | Alpine Linux | `apk` |
| `void` | Void Linux | `xbps` |
| `bazzite` | Fedora + stack de jogos | `dnf` + RPM Fusion |

> **`bazzite`** é um **perfil gamer** (Fedora + Steam/Lutris/GameMode/MangoHud), não o sistema imutável do Bazzite. O Bazzite real é uma imagem OCI/Fedora Atomic e não roda via `proot-distro`.

---

## 🖥️ Demonstração

Instalando o Ubuntu por cima do Android via Termux — repare que é só o Termux rodando, **nada de dual boot**:

<img src="assets/terminal-demo.svg" alt="ASLM demo no Termux instalando Ubuntu por cima do Android" width="100%">

---

## 🚫 Sem dual boot (como funciona)

- O ASLM roda **100% dentro do Android**, como um app (Termux).
- **Não** altera o bootloader, **não** cria partição, **não** reinicia o aparelho.
- O Android continua intacto e seus apps continuam funcionando normalmente.
- Linux e Android rodam **ao mesmo tempo** — você alterna só mudando de app.
- Para desinstalar: `bash scripts/setup-distro.sh remove <distro>` ou apague o Termux.

---

## 📦 Requisitos

- Android **8.0 (Oreo)+** (recomendado 10+)
- [Termux](https://f-droid.org/packages/com.termux/) (instale pela F-Droid, não pelo Play Store — a versão do Play está desatualizada)
- ~4–8 GB de espaço livre (Arch base ~1 GB; Steam+games muito mais)
- Para **macOS**: aparelho/dispositivo **x86_64** com `/dev/kvm` (celulares ARM64 **não** suportam)

---

## 🚀 Baixar e instalar o ASLM (via Termux)

O ASLM é **baixado e executado dentro do [Termux](https://f-droid.org/packages/com.termux/)** — o terminal Linux que roda no propio Android. Tudo acontece no celular: **sem root e sem dual boot**.

### 1. Instale o Termux

Baixe o Termux pela **F-Droid** (não use a versão da Play Store, que está desatualizada):

👉 https://f-droid.org/packages/com.termux/

### 2. Baixe o ASLM dentro do Termux

Abra o Termux e rode:

```sh
pkg update && pkg upgrade -y
pkg install -y git proot-distro
git clone https://github.com/davisoliveira1520-cmd/ASL-ANDROID-SUBSISTEMY-FOR-LINUX-.git
cd ASL-ANDROID-SUBSISTEMY-FOR-LINUX-
```

### 3. Rode o instalador

```sh
bash scripts/bootstrap.sh            # Arch Linux (padrão)
bash scripts/bootstrap.sh ubuntu     # ou escolha outra distro
bash scripts/bootstrap.sh bazzite    # perfil gamer (Fedora + jogos)
```

> **Prefere um comando só (sem clonar)?** Baixe e rode direto no Termux:
> ```sh
> curl -fsSL https://raw.githubusercontent.com/davisoliveira1520-cmd/ASL-ANDROID-SUBSISTEMY-FOR-LINUX-/main/scripts/bootstrap.sh | bash -s -- ubuntu
> ```
> (troque `ubuntu` por `archlinux`, `debian`, `fedora`, `bazzite`, etc.)

---

## 📚 Uso

```sh
# Gerenciar distros
bash scripts/setup-distro.sh list            # lista distros suportadas
bash scripts/setup-distro.sh install ubuntu  # instala Ubuntu
bash scripts/setup-distro.sh install bazzite # perfil gamer (Fedora + jogos)
bash scripts/setup-distro.sh shell ubuntu    # abre o shell

# Atalho único (criado pelo bootstrap) — usa a distro padrão
aslm                       # entra na distro padrão (Arch)
aslm ubuntu                # entra no Ubuntu
aslm -- neofetch           # roda um comando dentro da distro

# Camada de jogos estilo Bazzite
bash scripts/setup-steam.sh setup archlinux
bash scripts/setup-steam.sh start archlinux

# Runner do macOS (só x86_64 + KVM)
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
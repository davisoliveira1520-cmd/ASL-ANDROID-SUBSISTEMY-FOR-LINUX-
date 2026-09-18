# Compatibilidade e limites

## Resumo

| Recurso | ARM64 (celular) | x86_64 (PC/tablet Android, emulador) |
|---|---|---|
| Arch/Ubuntu/Debian/Fedora/Alpine via proot | ✅ OK | ✅ OK |
| Steam | 🧪 lento (box64, títulos leves) | ✅ OK |
| Jogos triplo-A | ❌ não | 🧪 depende de GPU/KVM |

## Distros suportadas

Todas rodam tanto em ARM64 quanto em x86_64 (o `proot-distro` baixa o rootfs
da arquitetura correta automaticamente).

| Nome | Base | Pacotes |
|---|---|---|
| `archlinux` / `manjaro` | Arch | `pacman` |
| `ubuntu` / `debian` | Debian | `apt` |
| `fedora` / `rocky` / `alma` | Red Hat | `dnf` |
| `opensuse` | SUSE | `zypper` |
| `alpine` | Alpine | `apk` |
| `void` | Void | `xbps` |
| `bazzite` | Fedora + jogos | `dnf` (+ RPM Fusion) |

> **Sobre o `bazzite`:** é um perfil de jogos, não o Bazzite oficial. O Bazzite
> real é uma imagem imutável (Fedora Atomic / OCI) distribuída em `.iso` e
> container; ele **não** é uma distro instalável pelo `proot-distro`. O perfil
> ASLM instala Fedora + Steam/Lutris/GameMode/MangoHud para dar a mesma
> experiência de jogos dentro do proot.

## Perguntas frequentes

### Preciso de root?
Não. O ASLM é **root-free por design** (igual ao WSL1): tudo roda em userspace
via proot, no Termux.

### Por que não é preciso root (igual ao WSL1)?
O WSL1 roda Linux no Windows **traduzindo chamadas de sistema** — sem VM e
sem kernel próprio. O `proot` faz exatamente isso no Android: traduz as
chamadas do userspace GNU para o kernel do Android, **sem root e sem
desbloquear o boot**. Qualquer abordagem "nativa" (chroot com kernel direto)
exige root e foge do espírito WSL do projeto. O ASLM é root-free por design;
soluções de root (LinuxDeploy, etc.) existem fora do escopo do ASLM.

### Linux já não é o Android?
O Android usa um kernel Linux, mas não traz um *userspace* GNU completo.
O ASLM adiciona distros completas (Arch, Ubuntu, Debian, Fedora...) com seus
repositórios oficiais, gerenciadores de pacotes e ferramentas de jogos.

### Posso rodar o WhatsApp/Instagram no Linux?
Não é o objetivo. Rodar apps Android de novo num Linux hosts exige
Waydroid/Anbox, que não fazem parte do ASLM (mas podem viver ao lado).

### Vai assumir o boot do aparelho? (dual boot)
Não. Nada é gravado na partição de boot, não há dual boot, não há risco de
"brickar". Tudo vive em diretórios do Termux. Para remover: exclua o app
(ou `bash scripts/setup-distro.sh remove archlinux`).

## Limitações conhecidas

- **proot é mais lento** que chroot/contêiner: I/O e processos pesados têm
  overhead maior. Em celulares topo de linha é ok para uso diário.
- **Steam em ARM64**: box64 traduz instruções, o que consome CPU. Espere
  lentidão; jogue títulos leves. Não é garantia de funcionamento.
- **Rede**: algumas redes bloqueiam pares de dados do Steam; use VPN se preciso.
- **Armazenamento**: Termux usa `~/`, então fique atento ao espaço
  (App Info → Armazenamento no Android).

## Problemas comuns e soluções

| Sintoma | Solução |
|---|---|
| `pkg` não encontrado | Instale Termux pela **F-Droid**, não Play Store |
| `pacman -Syu` estourando espaço | `pkg clean` + `du -sh ~/.local/share/proot-distro` |
| Steam abre e some | Rode `bash scripts/setup-steam.sh start` e leia os logs |
| Tela preta no termux-x11 | Atualize termos-x11-nightly e reinicie |
| `box64 not found` | Rode `setup-steam.sh` de novo (ele instala box64 em ARM) |

## Abrindo issue

Ao reportar um problema informe sempre:
- Modelo do aparelho e Android/SO
- `uname -m` (Termux)
- Saída do comando que falhou
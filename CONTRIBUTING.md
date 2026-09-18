# Contribuindo com o ASLM

Valeu pelo interesse! O ASLM é uma camada de orquestração sobre projetos
upstream (archlinux/linux, termux/proot-distro, ublue-os/bazzite).
Contribuições de scripts e documentação são bem-vindas.

## Antes de abrir PR

1. Mantenha os scripts POSIX-ish/bash limpos:
   ```sh
   shellcheck -S warning scripts/*.sh
   ```
2. Teste o script no Termux quando possível.
3. Descreva o aparelho, `uname -m` e Android/versão no PR.

## Padrões

- Prefixe mensagens com `[ASLM]`.
- Nunca faça `git` commit de rootfs, cache do Termux ou dados pessoais.
- O ASLM é **root-free por design** (igual ao WSL1). Não adicione scripts,
  comandos ou instruções que exijam root ou modifiquem o sistema Android.

## Reportando bugs

Abra uma issue com: aparelho, SO, `uname -m`, comando executado e log.
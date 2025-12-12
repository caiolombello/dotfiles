# Ubuntu / Pop!_OS (base Ubuntu) setup

Esta pasta contém scripts e listas de pacotes para sistemas **baseados em Ubuntu** (inclui Pop!_OS).

## Como usar (recomendado)

1) Clone o repo e rode o setup:

```bash
git clone <seu-repo> dotfiles
cd dotfiles
./Ubuntu/setup_ubuntu.sh --all
```

## Flags úteis

- `--base`: instala pacotes base via APT (zsh, git, curl, ripgrep, fzf, etc)
- `--desktop`: instala pacotes “desktop” via APT (alacritty, flameshot, gnome-tweaks, earlyoom, etc)
- `--cursor`: instala o Cursor via repositório oficial APT
- `--docker`: instala Docker (best-effort) e adiciona seu usuário ao grupo `docker`
- `--flatpak`: instala flatpak e adiciona Flathub
- `--flatpak-apps`: instala apps via Flatpak (lista em `Ubuntu/packages/flatpak-apps.txt`)
- `--gpg`: roda `scripts/gpg/setup_gpg.sh`
- `--bootstrap`: roda `scripts/bootstrap.sh` (Zsh + VSCode settings + scripts)
- `--all`: tudo acima

## Exportar inventário do sistema atual (antes de migrar)

No sistema antigo, rode `Ubuntu/export_installed.sh` para salvar:
- pacotes APT manuais
- lista de Flatpaks

```bash
./Ubuntu/export_installed.sh
```



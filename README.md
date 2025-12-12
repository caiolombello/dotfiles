# Dotfiles Repository

[English](#english) | [Português](#português)

## English

This repository contains my personal dotfiles and configuration scripts for setting up a development environment. It includes configurations for various tools and applications, with a focus on Fedora Linux and KDE Plasma.

### Repository Structure

```
.
├── Fedora/                  # Fedora-specific configurations
├── Ubuntu/                  # Ubuntu/Pop!_OS (Ubuntu-based) setup
│   ├── autocustom-plasma6-macos/  # KDE Plasma 6 macOS-like customization
│   └── cron.sh             # Cron job configurations
├── git/                    # Git configurations
├── shell/                  # Shell configurations
│   ├── config/            # Shell configuration files
│   └── install_zsh.sh     # ZSH installation script
└── vscode/                # VS Code configurations
```

### Features

- **Fedora Customization**
  - KDE Plasma 6 macOS-like theme and layout
  - System-wide configurations
  - Cron job management

- **Shell Configuration**
  - ZSH setup with Oh My Zsh
  - Custom shell configurations
  - GPG key management

- **Development Tools**
  - VS Code settings and extensions
  - Git configurations
  - Development environment setup

- **Git + SSH (multi-client ready)**
  - Base `~/.gitconfig` versioned + per-client configs using `includeIf "gitdir:"`
  - SSH config with per-client host aliases via `~/.ssh/config.d/`
  - Global gitignore via `core.excludesfile`
  - Editor wrapper `git-editor` (cursor/code/vim fallback)
  - Project helper scripts: `new_client`, `new_project`
  - Backup helpers (outside repo): `export_secrets`, `import_secrets`

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

2. Run the desired installation script:
   ```bash
   # For ZSH installation
   ./shell/install_zsh.sh

   # Bootstrap (recommended on Pop!_OS/Ubuntu)
   ./scripts/bootstrap.sh

   # Ubuntu/Pop!_OS full setup (recommended)
   ./Ubuntu/setup_ubuntu.sh --all

   # For KDE Plasma 6 macOS-like customization
   ./Fedora/autocustom-plasma6-macos/install_fedora.sh
   ```

### Pop!_OS / Ubuntu notes

- **Zsh setup is symlink-based**: `~/.zshrc` points to `shell/config/.zshrc`, so updates in this repo are reflected immediately.
- **Oh My Posh**: you’ll want a Nerd Font in your terminal for icons (e.g. Hack Nerd Font, JetBrainsMono Nerd Font).
- **Tool name differences are handled** (e.g. `bat` vs `batcat`, `fd` vs `fdfind`, `exa` vs `eza`).

### Migration checklist (recommended)

- **SSH**: backup `~/.ssh/` (keys, config).
- **GPG**: backup `~/.gnupg/` and/or export keys (see `scripts/gpg/README.md`).
- **Git identity**: keep `~/.gitconfig` (or reconfigure with `scripts/git/gcfg`).
- **Editors**: VS Code settings can be linked via `./scripts/bootstrap.sh`.
- **Language managers** (optional): `~/.nvm`, `~/.local/share/pnpm`, `~/.bun`, `~/.cargo`, `~/.dotnet`, `~/go`.

### Requirements

- Fedora Linux (for Fedora-specific configurations)
- KDE Plasma 6 (for macOS-like customization)
- Basic development tools (git, curl, etc.)

## Português

Este repositório contém meus dotfiles pessoais e scripts de configuração para configurar um ambiente de desenvolvimento. Inclui configurações para várias ferramentas e aplicativos, com foco no Fedora Linux e KDE Plasma.

### Estrutura do Repositório

```
.
├── Fedora/                  # Configurações específicas do Fedora
│   ├── autocustom-plasma6-macos/  # Personalização do KDE Plasma 6 estilo macOS
│   └── cron.sh             # Configurações de tarefas cron
├── git/                    # Configurações do Git
├── shell/                  # Configurações do shell
│   ├── config/            # Arquivos de configuração do shell
│   └── install_zsh.sh     # Script de instalação do ZSH
└── vscode/                # Configurações do VS Code
```

### Funcionalidades

- **Personalização do Fedora**
  - Tema e layout do KDE Plasma 6 estilo macOS
  - Configurações do sistema
  - Gerenciamento de tarefas cron

- **Configuração do Shell**
  - Configuração do ZSH com Oh My Zsh
  - Configurações personalizadas do shell
  - Gerenciamento de chaves GPG

- **Ferramentas de Desenvolvimento**
  - Configurações e extensões do VS Code
  - Configurações do Git
  - Configuração do ambiente de desenvolvimento

- **Git + SSH (pronto para múltiplos clientes)**
  - `~/.gitconfig` base versionado + configs por cliente usando `includeIf "gitdir:"`
  - SSH com aliases por cliente via `~/.ssh/config.d/`
  - Gitignore global via `core.excludesfile`
  - Wrapper de editor `git-editor` (fallback cursor/code/vim)
  - Scripts: `new_client`, `new_project`
  - Backup (fora do repo): `export_secrets`, `import_secrets`

### Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

2. Execute o script de instalação desejado:
   ```bash
   # Para instalação do ZSH
   ./shell/install_zsh.sh

   # Bootstrap (recomendado no Pop!_OS/Ubuntu)
   ./scripts/bootstrap.sh

   # Setup completo Ubuntu/Pop!_OS (recomendado)
   ./Ubuntu/setup_ubuntu.sh --all

   # Para personalização do KDE Plasma 6 estilo macOS
   ./Fedora/autocustom-plasma6-macos/install_fedora.sh
   ```

### Notas para Pop!_OS / Ubuntu

- **Setup de Zsh via symlink**: `~/.zshrc` aponta para `shell/config/.zshrc`, então alterações no repo refletem na hora.
- **Oh My Posh**: instale uma Nerd Font no terminal para ícones (ex.: Hack Nerd Font, JetBrainsMono Nerd Font).
- **Diferenças de nomes de ferramentas já são tratadas** (ex.: `bat` vs `batcat`, `fd` vs `fdfind`, `exa` vs `eza`).

### Checklist de migração (recomendado)

- **SSH**: faça backup de `~/.ssh/` (chaves e config).
- **GPG**: faça backup de `~/.gnupg/` e/ou exporte chaves (veja `scripts/gpg/README.md`).
- **Identidade do Git**: mantenha `~/.gitconfig` (ou reconfigure com `scripts/git/gcfg`).
- **Editor**: settings do VS Code podem ser linkadas via `./scripts/bootstrap.sh`.
- **Gerenciadores/SDKs** (opcional): `~/.nvm`, `~/.local/share/pnpm`, `~/.bun`, `~/.cargo`, `~/.dotnet`, `~/go`.

### Requisitos

- Fedora Linux (para configurações específicas do Fedora)
- KDE Plasma 6 (para personalização estilo macOS)
- Ferramentas básicas de desenvolvimento (git, curl, etc.)

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

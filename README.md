# Dotfiles Repository

[English](#english) | [Português](#português)

## English

This repository contains my personal dotfiles and configuration scripts for setting up a development environment. It includes configurations for various tools and applications, with a focus on Fedora Linux and KDE Plasma.

### Repository Structure

```
.
├── Fedora/                  # Fedora-specific configurations
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

   # For KDE Plasma 6 macOS-like customization
   ./Fedora/autocustom-plasma6-macos/install_fedora.sh
   ```

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

   # Para personalização do KDE Plasma 6 estilo macOS
   ./Fedora/autocustom-plasma6-macos/install_fedora.sh
   ```

### Requisitos

- Fedora Linux (para configurações específicas do Fedora)
- KDE Plasma 6 (para personalização estilo macOS)
- Ferramentas básicas de desenvolvimento (git, curl, etc.)

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

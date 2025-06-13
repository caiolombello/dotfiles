#!/bin/bash

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or with sudo"
        exit 1
    fi
}

# Function to install ZSH based on distribution
install_zsh() {
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu based
        apt-get update
        apt-get install -y zsh curl wget git
    elif command -v dnf &> /dev/null; then
        # Fedora based
        dnf install -y zsh curl wget git
    elif command -v pacman &> /dev/null; then
        # Arch based
        pacman -S --noconfirm zsh curl wget git
    else
        echo "Unsupported distribution"
        exit 1
    fi
}

# Function to install Oh My Posh
install_ohmyposh() {
    # Define variables
    OMP_BINARY="/usr/local/bin/oh-my-posh"
    OMP_DOWNLOAD_URL="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64"
    OMP_THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_modern.omp.json"

    # Download Oh My Posh binary if it doesn't already exist
    if [ -f "$OMP_BINARY" ]; then
        echo "Oh My Posh is already installed. Skipping download."
    else
        if wget "$OMP_DOWNLOAD_URL" -O "$OMP_BINARY"; then
            echo "Downloaded Oh My Posh binary successfully."
        else
            echo "Failed to download Oh My Posh binary."
            exit 1
        fi
    fi

    # Set execute permissions on the binary
    chmod +x "$OMP_BINARY"

    # Create necessary directories
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$HOME/.poshthemes"

    # Download the theme
    if wget "$OMP_THEME_URL" -O "$HOME/.poshthemes/powerlevel10k_modern.omp.json"; then
        echo "Downloaded Oh My Posh theme successfully."
    else
        echo "Failed to download Oh My Posh theme."
        exit 1
    fi

    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" <<EOF
Y
EOF

    # Install ZSH plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-history-substring-search "$HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search"
    git clone https://github.com/zsh-users/zsh-completions "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"

    # Install required tools
    if command -v apt-get &> /dev/null; then
        apt-get install -y exa bat ripgrep fd-find sd bottom gping hwatch git-delta kubectx kubens kubecolor dysk
    elif command -v dnf &> /dev/null; then
        dnf install -y exa bat ripgrep fd-find sd bottom gping hwatch git-delta kubectx kubens kubecolor dysk
    elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm exa bat ripgrep fd-find sd bottom gping hwatch git-delta kubectx kubens kubecolor dysk
    fi

    # Copy the custom .zshrc
    cp "$(dirname "$0")/config/.zshrc" "$HOME/.zshrc"

    # Set ZSH as default shell
    chsh -s "$(which zsh)" "$USER"
}

# Main execution
echo "Installing ZSH and Oh My Posh..."
check_root
install_zsh
install_ohmyposh
echo "Installation completed successfully!"
echo "Please log out and log back in for the changes to take effect."

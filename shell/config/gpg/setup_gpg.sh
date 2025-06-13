#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install GPG based on distribution
install_gpg() {
    if command_exists dnf; then
        echo -e "${YELLOW}Installing GPG for Fedora/RHEL...${NC}"
        sudo dnf install -y gnupg2 pinentry
    elif command_exists apt-get; then
        echo -e "${YELLOW}Installing GPG for Ubuntu/Debian...${NC}"
        sudo apt-get update
        sudo apt-get install -y gnupg2 pinentry-gtk2
    elif command_exists pacman; then
        echo -e "${YELLOW}Installing GPG for Arch Linux...${NC}"
        sudo pacman -S --noconfirm gnupg pinentry
    else
        echo -e "${RED}Unsupported distribution${NC}"
        exit 1
    fi
}

# Function to generate GPG key
generate_gpg_key() {
    echo -e "${YELLOW}Generating new GPG key...${NC}"
    echo -e "${YELLOW}Please follow the prompts:${NC}"
    echo -e "1. Choose RSA and RSA (default)"
    echo -e "2. Choose 4096 bits"
    echo -e "3. Choose 0 = key does not expire"
    echo -e "4. Enter your name and email"
    echo -e "5. Enter a strong passphrase"

    gpg --full-generate-key
}

# Function to configure GPG agent
configure_gpg_agent() {
    echo -e "${YELLOW}Configuring GPG agent...${NC}"

    # Create .gnupg directory if it doesn't exist
    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg

    # Configure GPG to use agent
    echo "use-agent" >> ~/.gnupg/gpg.conf

    # Configure pinentry
    if command_exists pinentry-gtk-2; then
        echo "pinentry-program /usr/bin/pinentry-gtk-2" >> ~/.gnupg/gpg-agent.conf
    elif command_exists pinentry; then
        echo "pinentry-program /usr/bin/pinentry" >> ~/.gnupg/gpg-agent.conf
    fi

    # Set permissions
    chmod 600 ~/.gnupg/gpg.conf
    chmod 600 ~/.gnupg/gpg-agent.conf

    # Restart GPG agent
    gpgconf --kill gpg-agent
    gpgconf --launch gpg-agent
}

# Function to configure Git for GPG
configure_git_gpg() {
    echo -e "${YELLOW}Configuring Git for GPG...${NC}"

    # Get the key ID
    KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d'/' -f2)

    if [ -z "$KEY_ID" ]; then
        echo -e "${RED}No GPG key found. Please generate a key first.${NC}"
        exit 1
    fi

    # Configure Git
    git config --global user.signingkey "$KEY_ID"
    git config --global commit.gpgsign true

    echo -e "${GREEN}Git configured to use GPG key: $KEY_ID${NC}"
}

# Function to export public key
export_public_key() {
    echo -e "${YELLOW}Exporting public key...${NC}"

    # Get the key ID
    KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d'/' -f2)

    if [ -z "$KEY_ID" ]; then
        echo -e "${RED}No GPG key found. Please generate a key first.${NC}"
        exit 1
    fi

    # Export the key
    gpg --armor --export "$KEY_ID" > ~/gpg_public_key.txt

    echo -e "${GREEN}Public key exported to ~/gpg_public_key.txt${NC}"
    echo -e "${YELLOW}You can now add this key to GitHub/GitLab${NC}"
}

# Function to add GPG_TTY to shell config
add_gpg_tty() {
    echo -e "${YELLOW}Adding GPG_TTY to shell configuration...${NC}"

    # Detect shell
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    else
        echo -e "${RED}Unsupported shell${NC}"
        exit 1
    fi

    # Add GPG_TTY if not already present
    if ! grep -q "export GPG_TTY" "$SHELL_RC"; then
        echo -e "\n# GPG Configuration\nexport GPG_TTY=\$(tty)" >> "$SHELL_RC"
        echo -e "${GREEN}Added GPG_TTY to $SHELL_RC${NC}"
    else
        echo -e "${YELLOW}GPG_TTY already configured in $SHELL_RC${NC}"
    fi
}

# Main execution
echo -e "${GREEN}Starting GPG setup...${NC}"

# Check if GPG is installed
if ! command_exists gpg; then
    install_gpg
fi

# Generate key if none exists
if ! gpg --list-secret-keys --keyid-format LONG | grep -q "sec"; then
    generate_gpg_key
fi

# Configure GPG agent
configure_gpg_agent

# Configure Git
configure_git_gpg

# Export public key
export_public_key

# Add GPG_TTY to shell config
add_gpg_tty

echo -e "${GREEN}GPG setup completed successfully!${NC}"
echo -e "${YELLOW}Please add your public key to GitHub/GitLab${NC}"
echo -e "${YELLOW}You can find your public key in ~/gpg_public_key.txt${NC}"

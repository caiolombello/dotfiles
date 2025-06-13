#!/bin/bash
#
# Script Name: install_fedora.sh
# Version : 2.0
# Description: Installation script auto customization
# KDE Plasma 6 Look Like macOS layout
#
# For Linux : Fedora 40 KDE Edition
# For Desktop Environment : KDE Plasma 6
# Author: linuxscoop
# Youtube: https://youtube.com/user/linuxscoop
# Created: Nov 21, 2024
# Last Modified: Nov 25, 2024
# Function to prompt for sudo password and exit if incorrect
PLASMA6MACOS_check_sudo() {
  if ! sudo -v; then
    echo "Incorrect sudo password. Exiting."
    exit 1
  fi

  # Keep sudo alive until the script finishes
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}
# Function to update the system
PLASMA6MACOS_update_system() {
    sudo dnf update -y
}

# Function to install command line apps and dependencies
PLASMA6MACOS_install_dependencies() {
    sudo dnf install -y qt5-qttools \
                        curl \
                        wget \
                        rsync \
                        git \
                        nautilus \
                        gnome-terminal-nautilus \
                        sassc
}

# Function to install GNOME apps
PLASMA6MACOS_install_gnome_apps() {
    sudo dnf install -y gnome-weather \
                        gnome-maps \
                        gnome-calendar \
                        gnome-clocks \
                        vlc
}
# Function to install the Zsh shell
PLASMA6MACOS_install_zsh_shell() {
    sudo dnf install -y zsh
    sudo chsh -s $(which zsh)
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" <<EOF
Y
EOF
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search
}

# Function to install Oh My Posh
PLASMA6MACOS_install_ohmyposh() {
    # Define variables
    OMP_BINARY="/usr/local/bin/oh-my-posh"
    OMP_DOWNLOAD_URL="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64"

    # Download Oh My Posh binary if it doesn't already exist
    if [ -f "$OMP_BINARY" ]; then
        echo "Oh My Posh is already installed. Skipping download."
    else
        if sudo wget "$OMP_DOWNLOAD_URL" -O "$OMP_BINARY"; then
            echo "Downloaded Oh My Posh binary successfully."
        else
            echo "Failed to download Oh My Posh binary."
            exit 1
        fi
    fi
    # Set execute permissions on the binary
    sudo chmod +x "$OMP_BINARY"
    # Unzip configuration files
    if unzip -o assets/plasma6macos-zshomh-config.zip -d "$HOME"; then
        echo "Fish Shell and Oh My Posh config installed successfully."
    else
        echo "Failed to unzip Fish Shell and Oh My Posh."
        exit 1
    fi

    # Set permissions for themes
    if chmod u+rw "$HOME/.poshthemes/"*.json; then
        echo "Set read and write permissions for Oh My Posh themes."
    else
        echo "Failed to set permissions for Oh My Posh themes."
    fi

    echo "Oh My Posh installation completed."
}

# Function to enable Flatpak, AppImage support, and add Flathub repository
PLASMA6MACOS_enable_flatpak_appimage() {
    sudo dnf install -y flatpak fuse
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Install Flatpak applications
PLASMA6MACOS_install_flatpak_apps() {
    flatpak install -y flathub io.bassi.Amberol com.mattjakeman.ExtensionManager com.github.KRTirtho.Spotube
    # make flatpak apps follow active theme
    # sudo flatpak override --filesystem=$HOME/.themes
    # sudo flatpak override --filesystem=$HOME/.local/share/icons
    # sudo flatpak override --filesystem=xdg-config/gtk-4.0
    OVERRIDE_FILE="$HOME/.local/share/flatpak/overrides/global"

    # Ensure the overrides directory exists
    mkdir -p "$(dirname "$OVERRIDE_FILE")"

    # Write the new content to the global file, replacing any existing content
    cat <<EOL > "$OVERRIDE_FILE"
    [Context]
    filesystems=~/.local/share/icons;~/.themes;xdg-config/gtk-4.0;xdg-config/gtk-3.0
EOL

    echo "Flatpak overrides have been set in $OVERRIDE_FILE"
}

PLASMA6MACOS_install_plasma_theme() {
    unzip -o assets/plasma6macos-plasma-theme.zip -d $HOME
}

# Function to install Kvantum Manager
PLASMA6MACOS_install_kvantum_manager() {
    sudo dnf install kvantum -y
    unzip -o assets/plasma6macos-kvantum-config.zip -d $HOME
}

PLASMA6MACOS_install_gtk_theme() {
    unzip -o assets/plasma6macos-gtk-theme-config.zip -d $HOME
}

PLASMA6MACOS_install_icon_theme() {
    unzip -o assets/plasma6macos-icon-packs.zip -d $HOME
}

PLASMA6MACOS_install_cursors_theme() {
    unzip -o assets/plasma6macos-cursors.zip -d $HOME
}

PLASMA6MACOS_install_fonts() {
    unzip -o assets/plasma6macos-font-packs.zip -d $HOME
}

PLASMA6MACOS_install_wallpapers() {
    unzip -o assets/plasma6macos-wallpaper-packs.zip -d $HOME
}

PLASMA6MACOS_install_konsole_profile() {
    unzip -o assets/plasma6macos-konsole-profile.zip -d $HOME
}

PLASMA6MACOS_install_plasmoids_widget() {
    unzip -o assets/plasma6macos-plasmoids-widget.zip -d $HOME
}

# Function to install the Plymouth macOS theme
PLASMA6MACOS_install_plymouth() {
    sudo dnf install -y plymouth plymouth-theme-script
    sudo unzip -o assets/plasma6macos-plymouth-config.zip -d /
    sudo plymouth-set-default-theme -R macOS
}
# Function to install Albert
PLASMA6MACOS_install_albert() {
    sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:manuelschneid3r/Fedora_40/home:manuelschneid3r.repo
    sudo dnf install albert -y
    unzip -o assets/plasma6macos-albertlauncher-config.zip -d $HOME
    sudo unzip -o assets/plasma6macos-albertlauncher-theme.zip -d /
}

# Function to install the SDDM macOS Sequoia theme
PLASMA6MACOS_install_sddm_theme() {
    sudo unzip -o assets/plasma6macos-sddm-config.zip -d /
}

# Function to install Plasma 6 macOS resources
PLASMA6MACOS_install_plasma6macos_config() {
    kquitapp6 plasmashell
    unzip -o assets/plasma6macos-kde-config.zip -d $HOME
    kstart plasmashell &> /dev/null &
    dconf load / < assets/plasma6macos-gnome-config.conf
    #Enable gtk theme dark mode
    ln -sf "$HOME/.config/gtk-4.0/gtk-Dark.css" "$HOME/.config/gtk-4.0/gtk.css"
}

# Function to install Firefox Safari theme
PLASMA6MACOS_install_firefox_safari_theme() {
# Create and enter src directory
    [ ! -d "src" ] && mkdir src
    cd src || exit

    # Check if WhiteSur-gtk-theme exists
    if [ ! -d "WhiteSur-gtk-theme" ]; then
        git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    fi

    # Enter the directory and run the tweaks script
    cd WhiteSur-gtk-theme || exit
    ./tweaks.sh -f monterey 5+5

    # Return to previous directory
    cd ../..
}

# Function to install KWin effects force blur
PLASMA6MACOS_install_kwin_effect() {
    unzip -o assets/plasma6macos-kwin-effect.zip -d $HOME
    sudo dnf install -y git \
                        cmake extra-cmake-modules \
                        gcc-g++ \
                        kf6-kwindowsystem-devel \
                        plasma-workspace-devel \
                        libplasma-devel \
                        qt6-qtbase-private-devel \
                        qt6-qtbase-devel \
                        kwin-devel \
                        kf6-knotifications-devel \
                        kf6-kio-devel \
                        kf6-kcrash-devel \
                        kf6-ki18n-devel \
                        kf6-kguiaddons-devel \
                        libepoxy-devel \
                        kf6-kglobalaccel-devel \
                        kf6-kcmutils-devel \
                        kf6-kconfigwidgets-devel \
                        kf6-kdeclarative-devel \
                        kdecoration-devel \
                        wayland-devel
    # Create and enter src directory
    [ ! -d "src" ] && mkdir src
    cd src || exit

    # Clone and install kwin-effects-forceblur
    if [ ! -d "kwin-effects-forceblur" ]; then
        git clone https://github.com/taj-ny/kwin-effects-forceblur.git
    fi

    cd kwin-effects-forceblur || exit
    mkdir -p build
    cd build || exit
    cmake ../ -DCMAKE_INSTALL_PREFIX=/usr
    make
    sudo make install

    # Return to previous directory
    cd ../../..
}
# Function to prompt for logout after setup completion
PLASMA6MACOS_prompt_for_logout() {
    clear
    read -p "Setup completed successfully. Please logout and log back in for changes to take effect. (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
    else
        clear
        echo "You can manually logout and log back in later."
    fi
}

# Start the script execution
clear
echo "============================================================="
echo " Auto Customize KDE Plasma 6 Look Like macoS on Fedora WS 40 "
echo "============================================================="
# Detailed prompt for user confirmation
echo
read -p "Would you like to proceed with the customization? (yes/no): " response

# Check the response
if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    echo "Great choice! Starting the customization process... 🎉"
    PLASMA6MACOS_check_sudo
    clear
    echo "Updating your system with new packages..."
    PLASMA6MACOS_update_system
    clear
    echo "Installing Dependencies..."
    PLASMA6MACOS_install_dependencies
    clear
    echo "Installing GNOME Apps..."
    PLASMA6MACOS_install_gnome_apps
    clear
    echo "Installing Plasma 6 macOS Theme..."
    PLASMA6MACOS_install_plasma_theme
    clear
    echo "Installing Kvantum Manager and Theme..."
    PLASMA6MACOS_install_kvantum_manager
    clear
    echo "Installing GTK macOS Theme..."
    PLASMA6MACOS_install_gtk_theme
    clear
    echo "Installing Icon Theme..."
    PLASMA6MACOS_install_icon_theme
    clear
    echo "Installing Cursors Theme..."
    PLASMA6MACOS_install_cursors_theme
    clear
    echo "Installing Fonts and Wallpapers..."
    PLASMA6MACOS_install_fonts
    PLASMA6MACOS_install_wallpapers
    clear
    echo "Enable Flatpak and AppImage Support..."
    PLASMA6MACOS_enable_flatpak_appimage
    clear
    echo "Installing Flatpak Apps..."
    PLASMA6MACOS_install_flatpak_apps
    clear
    echo "Installing ZSH Shell + OhMyPOSH..."
    PLASMA6MACOS_install_zsh_shell
    PLASMA6MACOS_install_ohmyposh
    clear
    echo "Installing Konsole terminal profile..."
    PLASMA6MACOS_install_konsole_profile
    clear
    echo "Installing SDDM theme..."
    PLASMA6MACOS_install_sddm_theme
    clear
    echo "Installing PlyMouth Theme..."
    PLASMA6MACOS_install_plymouth
    clear
    echo "Installing Albert Launcher..."
    PLASMA6MACOS_install_albert
    clear
    echo "Installing Plasmoids Widgets..."
    PLASMA6MACOS_install_plasmoids_widget
    clear
    echo "Installing KWin Effect..."
    PLASMA6MACOS_install_kwin_effect
    clear
    echo "Installing Safari Theme for Firefox..."
    PLASMA6MACOS_install_firefox_safari_theme
    clear
    echo "Installing Plasma 6 macoS Configurations..."
    PLASMA6MACOS_install_plasma6macos_config
    clear
    PLASMA6MACOS_prompt_for_logout
    else
        echo "Got it! If you change your mind, just run this script again. 😊"
fi

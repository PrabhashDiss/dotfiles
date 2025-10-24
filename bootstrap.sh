#!/bin/bash

# Dotfiles Bootstrap Script
# Sets up development environment with essential tools and configurations
#
# New: interactive component selection
# - When run interactively the script prompts which components to install.
# - Provide a comma-separated list from: fzf, bat, tmux, neovim, fish, shell, tmuxconf, fzfinit
# - Use 'all' or press Enter to install everything. Example: "fzf,tmux" installs only fzf and tmux.
# - In non-interactive shells (or CI) the script defaults to installing all components.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a package is installed via apt
package_installed() {
    dpkg -l "$1" >/dev/null 2>&1
}

# Update package list
update_package_list() {
    log_info "Updating package list..."
    sudo apt update -qq
    log_success "Package list updated"
}

# Install fzf
install_fzf() {
    log_info "Checking fzf installation..."

    if command_exists fzf; then
        log_success "fzf is already installed"
        log_info "fzf version: $(fzf --version)"
        return 0
    fi

    if package_installed fzf; then
        log_success "fzf package is already installed via apt"
        return 0
    fi

    log_info "Installing fzf..."
    sudo apt install -y fzf

    if command_exists fzf; then
        log_success "fzf installed successfully"
        log_info "fzf version: $(fzf --version)"
    else
        log_error "fzf installation failed"
        return 1
    fi
}

# Install tmux
install_tmux() {
    log_info "Checking tmux installation..."

    if command_exists tmux; then
        log_success "tmux is already installed"
        log_info "tmux version: $(tmux -V)"
        return 0
    fi

    if package_installed tmux; then
        log_success "tmux package is already installed via apt"
        return 0
    fi

    log_info "Installing tmux..."
    sudo apt install -y tmux

    if command_exists tmux; then
        log_success "tmux installed successfully"
        log_info "tmux version: $(tmux -V)"
    else
        log_error "tmux installation failed"
        return 1
    fi
}

# Set up tmux configuration
setup_tmux() {
    log_info "Setting up tmux configuration..."

    local dotfiles_dir="$(pwd)"
    local tmux_conf="$dotfiles_dir/tmux/tmux.conf"
    local home_tmux_conf="$HOME/.tmux.conf"

    if [[ -f "$tmux_conf" ]]; then
        # Check if symlink already exists and points to our config
        if [[ -L "$home_tmux_conf" ]] && [[ "$(readlink "$home_tmux_conf")" == "$tmux_conf" ]]; then
            log_success "tmux configuration already linked"
        else
            # Remove existing config if it exists
            if [[ -f "$home_tmux_conf" ]] && [[ ! -L "$home_tmux_conf" ]]; then
                rm "$home_tmux_conf"
                log_info "Removed existing ~/.tmux.conf"
            fi

            # Create symlink
            ln -sf "$tmux_conf" "$home_tmux_conf"
            log_success "tmux configuration linked to ~/.tmux.conf"
        fi
    else
        log_warning "tmux configuration file not found at $tmux_conf"
    fi
}

# Install grc
install_grc() {
    log_info "Checking grc installation..."

    if command_exists grc; then
        log_success "grc is already installed"
        log_info "grc version: $(grc --version 2>/dev/null || echo 'version unknown')"
    else
        if package_installed grc; then
            log_success "grc package is already installed via apt"
        else
            log_info "Installing grc..."
            sudo apt install -y grc

            if command_exists grc; then
                log_success "grc installed successfully"
                log_info "grc version: $(grc --version 2>/dev/null || echo 'version unknown')"
            else
                log_error "grc installation failed"
                return 1
            fi
        fi
    fi

    # Configure grc in ~/.bashrc (enable aliases and source system grc if present)
    if ! grep -q "GRC_ALIASES=true" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# grc colorizer configuration" >> ~/.bashrc
        echo "GRC_ALIASES=true" >> ~/.bashrc
        echo '[[ -s "/etc/profile.d/grc.sh" ]] && source /etc/grc.sh' >> ~/.bashrc
        log_success "grc configuration added to ~/.bashrc"
    else
        log_success "grc configuration already present in ~/.bashrc"
    fi
}

# Install neovim
install_neovim() {
    log_info "Checking neovim installation..."

    # if command_exists nvim; then
    #     log_success "neovim is already installed"
    #     log_info "neovim version: $(nvim --version | head -n1)"
    #     return 0
    # fi

    log_info "Installing neovim from GitHub releases..."

    # Download and install neovim
    if curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; then
        sudo rm -rf /opt/nvim-linux-x86_64 || true
        sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        rm -f nvim-linux-x86_64.tar.gz

        # Verify installation
        if command_exists nvim; then
            log_success "Successfully installed neovim"
            log_info "Installed neovim version: $(nvim --version | head -n1)"

            # Configure Neovim by cloning my kickstart.nvim
            log_info "Setting up Neovim configuration using kickstart.nvim..."

            # Determine target config dir
            local nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

            # Backup existing config if present
            if [[ -e "$nvim_config_dir" ]]; then
                local backup_dir="$nvim_config_dir.backup.$(date +%Y%m%d%H%M%S)"
                mv "$nvim_config_dir" "$backup_dir"
                log_info "Existing Neovim config moved to $backup_dir"
            fi

            # Clone via SSH
            local repo_ssh="git@github-personal:PrabhashDiss/kickstart.nvim.git"

            mkdir -p "$(dirname "$nvim_config_dir")"

            if git clone "$repo_ssh" "$nvim_config_dir" 2>/dev/null; then
                log_success "Cloned kickstart.nvim (SSH) into $nvim_config_dir"
            else
                log_warning "SSH clone failed"
                return 1
            fi

            log_info "Neovim configuration installed. Launch Neovim and run :Lazy to install plugins or restart nvim to let lazy.nvim install them on first start."
        else
            log_error "Failed to verify neovim installation"
            return 1
        fi
    else
        log_error "Failed to download neovim"
        return 1
    fi
}

# Install fish shell
install_fish() {
    log_info "Checking fish installation..."

    if command_exists fish; then
        log_success "fish is already installed"
        log_info "fish version: $(fish --version)"
        return 0
    fi

    if package_installed fish; then
        log_success "fish package is already installed via apt"
        return 0
    fi

    log_info "Adding fish PPA and installing fish..."

    # Ensure add-apt-repository is available
    if ! command_exists apt-add-repository; then
        log_info "Installing software-properties-common so we can add PPAs..."
        sudo apt update -qq
        sudo apt install -y software-properties-common
    fi

    # Use apt-add-repository
    sudo apt-add-repository -y ppa:fish-shell/release-4

    # Update package list after adding PPA and install fish
    sudo apt update -qq
    sudo apt install -y fish

    if command_exists fish; then
        log_success "fish installed successfully"
        log_info "fish version: $(fish --version)"
    else
        log_error "fish installation failed"
        return 1
    fi
}

# Install bat for better file previews
install_bat() {
    log_info "Checking bat installation..."

    if command_exists bat; then
        log_success "bat is already installed"
        log_info "bat version: $(bat --version | head -n1)"
        return 0
    fi

    log_info "Installing bat from GitHub releases..."

    # Get the latest release tag
    local tag
    tag=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "$tag" ]]; then
        log_error "Failed to get latest bat release tag"
        return 1
    fi

    local url="https://github.com/sharkdp/bat/releases/download/$tag/bat-$tag-x86_64-unknown-linux-musl.tar.gz"
    local temp_dir="/tmp/bat_install"

    # Create temp directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"

    # Download and extract
    if curl -L "$url" -o bat.tar.gz && tar -xzf bat.tar.gz; then
        # Find the extracted directory
        local extracted_dir
        extracted_dir=$(find . -name "bat-*" -type d | head -n1)

        if [[ -z "$extracted_dir" ]]; then
            log_error "Failed to find extracted bat directory"
            cd /
            rm -rf "$temp_dir"
            return 1
        fi

        # Install bat binary
        mkdir -p "$HOME/.local/bin"
        cp "$extracted_dir/bat" "$HOME/.local/bin/bat"
        chmod +x "$HOME/.local/bin/bat"

        # Clean up
        cd /
        rm -rf "$temp_dir"

        # Verify installation
        if command_exists bat; then
            log_success "Successfully installed bat"
            log_info "Installed bat version: $(bat --version | head -n1)"
        else
            log_error "Failed to verify bat installation"
            return 1
        fi
    else
        log_error "Failed to download or extract bat"
        cd /
        rm -rf "$temp_dir"
        return 1
    fi
}

# Install lsd
install_lsd() {
    log_info "Checking lsd installation..."

    if command_exists lsd; then
        log_success "lsd is already installed"
        log_info "lsd version: $(lsd --version)"
        return 0
    fi

    if package_installed lsd; then
        log_success "lsd package is already installed via apt"
        return 0
    fi

    log_info "Installing lsd..."
    sudo apt install -y lsd

    if command_exists lsd; then
        log_success "lsd installed successfully"
        log_info "lsd version: $(lsd --version)"

        # Set up lsd aliases in ~/.bashrc
        if ! grep -q "alias ls='lsd'" ~/.bashrc 2>/dev/null; then
            echo "" >> ~/.bashrc
            echo "# Use lsd instead of ls" >> ~/.bashrc
            echo "alias ls='lsd'" >> ~/.bashrc
            echo "alias ll='lsd -alF'" >> ~/.bashrc
            echo "alias la='lsd -A'" >> ~/.bashrc
            echo "alias l='lsd -CF'" >> ~/.bashrc
            log_success "lsd aliases added to ~/.bashrc"
        else
            log_success "lsd aliases already configured in ~/.bashrc"
        fi
    else
        log_error "lsd installation failed"
        return 1
    fi
}

# Install starship prompt
install_starship() {
    log_info "Checking starship installation..."

    if command_exists starship; then
        log_success "starship is already installed"
        log_info "starship version: $(starship --version)"
        return 0
    fi

    log_info "Installing starship..."
    if curl -sS https://starship.rs/install.sh | sh; then
        if command_exists starship; then
            log_success "starship installed successfully"
            log_info "starship version: $(starship --version)"

            # Set up starship in shell configuration
            local dotfiles_dir="$(pwd)"
            local bashrc_additions="$dotfiles_dir/shell/bashrc_additions"
            if [[ -f "$bashrc_additions" ]]; then
                if ! grep -q 'eval "$(starship init bash)"' "$bashrc_additions"; then
                    echo "" >> "$bashrc_additions"
                    echo "# Initialize starship prompt" >> "$bashrc_additions"
                    echo 'eval "$(starship init bash)"' >> "$bashrc_additions"
                    log_success "starship init added to shell configuration"
                else
                    log_success "starship init already configured"
                fi
            else
                log_warning "bashrc_additions file not found, starship init not added"
            fi
        else
            log_error "starship installation failed"
            return 1
        fi
    else
        log_error "Failed to download and install starship"
        return 1
    fi
}

# Set up shell configuration
setup_shell_config() {
    log_info "Setting up shell configuration..."

    # Install bash-completion if not present
    if ! package_installed bash-completion; then
        log_info "Installing bash-completion for enhanced shell autocompletion..."
        update_package_list
        sudo apt install -y bash-completion
        log_success "bash-completion installed"
    else
        log_success "bash-completion already installed"
    fi

    local dotfiles_dir="$(pwd)"
    local bashrc_additions="$dotfiles_dir/shell/bashrc_additions"

    # Check if shell config is already sourced in bashrc
    if grep -q "source.*bashrc_additions" ~/.bashrc 2>/dev/null; then
        log_success "Shell configuration already sourced in ~/.bashrc"
        return 0
    fi

    if [[ -f "$bashrc_additions" ]]; then
        # Add source line to bashrc
        echo "" >> ~/.bashrc
        echo "# Source dotfiles shell configuration" >> ~/.bashrc
        echo "if [[ -f \"$bashrc_additions\" ]]; then" >> ~/.bashrc
        echo "    source \"$bashrc_additions\"" >> ~/.bashrc
        echo "fi" >> ~/.bashrc

        log_success "Shell configuration added to ~/.bashrc"
        log_info "Includes enhanced aliases, fzf integration, and git-aware prompt"
    else
        log_warning "Shell configuration file not found at $bashrc_additions"
    fi
}

# Set up fzf key bindings and completion
setup_fzf() {
    log_info "fzf key bindings and completion are handled by shell configuration"

    # Verify fzf key bindings file exists
    if [[ -f "/usr/share/doc/fzf/examples/key-bindings.bash" ]]; then
        log_success "fzf key bindings found and will be loaded"
    else
        log_warning "fzf key bindings not found at expected location"
    fi

    # Verify fzf completion exists
    if [[ -f "/usr/share/bash-completion/completions/fzf" ]]; then
        log_success "fzf bash completion found and will be loaded"
    else
        log_warning "fzf bash completion not found"
    fi
}

# Main function
main() {
    log_info "Starting dotfiles bootstrap..."
    log_info "Current directory: $(pwd)"

    # Check if running on supported OS
    if [[ ! -f /etc/os-release ]] || ! grep -q "ubuntu\|debian" /etc/os-release; then
        log_warning "This script is designed for Ubuntu/Debian. Proceed with caution."
    fi

    # Selection: allow user to pick which components to install
    # Components: fzf,bat,tmux,grc,neovim,fish,shell,tmuxconf,fzfinit
    local all_components=(fzf bat lsd starship tmux grc neovim fish shell tmuxconf fzfinit)

    # Default selection behavior: if not running in a TTY, assume all
    local selection=""
    if [[ ! -t 0 ]]; then
        log_info "Non-interactive shell detected - defaulting to installing all components"
        selection="all"
    else
        echo
        echo "Choose components to install (comma-separated). Available: ${all_components[*]}"
        echo "Use 'all' to install everything, or press Enter to install all. Examples: fzf,tmux or fzf,bat,tmux"
        read -r -p "Install components: " selection
        selection=${selection:-all}
    fi

    # Normalize selection to lowercase and remove spaces
    selection=$(echo "$selection" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

    # Helper to check if a component is selected
    is_selected() {
        local name="$1"
        if [[ "$selection" == "all" ]]; then
            return 0
        fi
        IFS=',' read -ra parts <<< "$selection"
        for p in "${parts[@]}"; do
            if [[ "$p" == "$name" ]]; then
                return 0
            fi
        done
        return 1
    }

    # Update package list if any package install is requested
    if is_selected fzf || is_selected bat || is_selected lsd || is_selected tmux || is_selected grc || is_selected fish; then
        update_package_list
    fi

    # Install selected components
    if is_selected fzf; then
        install_fzf
    else
        log_info "Skipping fzf"
    fi

    if is_selected bat; then
        install_bat
    else
        log_info "Skipping bat"
    fi

    if is_selected lsd; then
        install_lsd
    else
        log_info "Skipping lsd"
    fi

    if is_selected starship; then
        install_starship
    else
        log_info "Skipping starship"
    fi

    if is_selected tmux; then
        install_tmux
    else
        log_info "Skipping tmux install"
    fi

    if is_selected grc; then
        install_grc
    else
        log_info "Skipping grc"
    fi

    if is_selected neovim; then
        install_neovim
    else
        log_info "Skipping neovim"
    fi

    if is_selected fish; then
        install_fish
    else
        log_info "Skipping fish"
    fi

    # Setup configurations
    if is_selected shell; then
        setup_shell_config
    else
        log_info "Skipping shell configuration"
    fi

    if is_selected tmuxconf; then
        setup_tmux
    else
        log_info "Skipping tmux configuration"
    fi

    if is_selected fzfinit; then
        setup_fzf
    else
        log_info "Skipping fzf key bindings/completion setup"
    fi

    log_success "Bootstrap completed successfully!"
    log_info "Enhanced aliases available: cdf (cd with fzf), kp (kill process)"
    log_info "Please restart your shell or run 'source ~/.bashrc' to apply changes"
}

# Run main function
main "$@"

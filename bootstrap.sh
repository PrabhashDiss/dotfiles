#!/bin/bash

# Dotfiles Bootstrap Script
# Sets up development environment with essential tools and configurations

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

# Install Neovim
install_neovim() {
    log_info "Checking Neovim installation..."
    
    if command_exists nvim; then
        log_success "Neovim is already installed"
        log_info "Neovim version: $(nvim --version | head -n1)"
        return 0
    fi
    
    if package_installed neovim; then
        log_success "Neovim package is already installed via apt"
        return 0
    fi
    
    log_info "Installing Neovim..."
    sudo apt install -y neovim
    
    if command_exists nvim; then
        log_success "Neovim installed successfully"
        log_info "Neovim version: $(nvim --version | head -n1)"
    else
        log_error "Neovim installation failed"
        return 1
    fi
}

# Set up NvChad configuration
setup_nvchad() {
    log_info "Setting up NvChad configuration..."
    
    local nvim_config_dir="$HOME/.config/nvim"
    
    # Check if NvChad is already installed
    if [[ -d "$nvim_config_dir" ]] && [[ -f "$nvim_config_dir/init.lua" ]]; then
        if grep -q "NvChad" "$nvim_config_dir/init.lua" 2>/dev/null; then
            log_success "NvChad is already installed"
            return 0
        fi
    fi
    
    # Backup existing Neovim configuration if it exists
    if [[ -d "$nvim_config_dir" ]]; then
        local backup_dir="$nvim_config_dir.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$nvim_config_dir" "$backup_dir"
        log_info "Backed up existing Neovim config to $backup_dir"
    fi
    
    # Clone NvChad
    log_info "Cloning NvChad configuration..."
    if git clone https://github.com/NvChad/starter "$nvim_config_dir" --depth 1; then
        log_success "NvChad configuration cloned successfully"
        log_info "Run 'nvim' to complete the setup - NvChad will install plugins automatically"
    else
        log_error "Failed to clone NvChad configuration"
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
            # Backup existing config if it exists
            if [[ -f "$home_tmux_conf" ]] && [[ ! -L "$home_tmux_conf" ]]; then
                mv "$home_tmux_conf" "$home_tmux_conf.backup"
                log_info "Backed up existing ~/.tmux.conf to ~/.tmux.conf.backup"
            fi
            
            # Create symlink
            ln -sf "$tmux_conf" "$home_tmux_conf"
            log_success "tmux configuration linked to ~/.tmux.conf"
        fi
    else
        log_warning "tmux configuration file not found at $tmux_conf"
    fi
}

# Install bat for better file previews
install_bat() {
    log_info "Checking bat installation..."
    
    if command_exists bat; then
        log_success "bat is already installed"
        log_info "bat version: $(bat --version | head -n1)"
        return 0
    elif command_exists batcat; then
        log_success "bat is already installed as batcat"
        log_info "bat version: $(batcat --version | head -n1)"
        return 0
    fi
    
    if package_installed bat; then
        log_success "bat package is already installed via apt"
        return 0
    fi
    
    log_info "Installing bat for enhanced file previews..."
    sudo apt install -y bat
    
    if command_exists bat; then
        log_success "bat installed successfully"
        log_info "bat version: $(bat --version | head -n1)"
    elif command_exists batcat; then
        log_success "bat installed successfully as batcat"
        log_info "bat version: $(batcat --version | head -n1)"
    else
        log_warning "bat installation failed, but continuing..."
    fi
}

# Set up shell configuration
setup_shell_config() {
    log_info "Setting up shell configuration..."
    
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
    
    # Update package list
    update_package_list
    
    # Install essential tools
    install_fzf
    install_bat
    install_tmux
    install_neovim
    
    # Setup configurations
    setup_shell_config
    setup_tmux
    setup_nvchad
    setup_fzf
    
    log_success "Bootstrap completed successfully!"
    log_info "Enhanced aliases available: vf (edit with fzf), cdf (cd with fzf), kp (kill process)"
    log_info "Please restart your shell or run 'source ~/.bashrc' to apply changes"
}

# Run main function
main "$@"
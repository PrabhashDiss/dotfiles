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

# Install bat for better file previews
install_bat() {
    log_info "Checking bat installation..."
    
    if command_exists bat; then
        log_success "bat is already installed"
        log_info "bat version: $(bat --version | head -n1)"
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

# Set up fzf key bindings and completion (legacy function for compatibility)
setup_fzf() {
    log_info "fzf setup is now handled by shell configuration"
    log_success "fzf key bindings will be available after shell reload"
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
    
    # Install and setup fzf
    install_fzf
    install_bat
    setup_shell_config
    setup_fzf
    
    log_success "Bootstrap completed successfully!"
    log_info "Enhanced aliases available: vf (edit with fzf), cdf (cd with fzf), kp (kill process)"
    log_info "Please restart your shell or run 'source ~/.bashrc' to apply changes"
}

# Run main function
main "$@"
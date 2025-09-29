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

# Set up fzf key bindings and completion
setup_fzf() {
    log_info "Setting up fzf key bindings and completion..."
    
    # Check if fzf bindings are already in bashrc
    if grep -q "fzf --bash" ~/.bashrc 2>/dev/null; then
        log_success "fzf key bindings already configured in ~/.bashrc"
        return 0
    fi
    
    # Add fzf bindings to bashrc
    echo "" >> ~/.bashrc
    echo "# fzf key bindings and fuzzy completion" >> ~/.bashrc
    echo 'eval "$(fzf --bash)"' >> ~/.bashrc
    
    log_success "fzf key bindings added to ~/.bashrc"
    log_info "Run 'source ~/.bashrc' or restart your shell to activate fzf bindings"
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
    setup_fzf
    
    log_success "Bootstrap completed successfully!"
    log_info "Please restart your shell or run 'source ~/.bashrc' to apply changes"
}

# Run main function
main "$@"
# 🏠 Dotfiles

A comprehensive dotfiles repository that sets up a complete development environment with essential tools and configurations in one go.

## ✨ What's Included

- **fzf** - Fuzzy finder with custom aliases and key bindings
- **Neovim** - Modern text editor with NvChad configuration
- **Tmux** - Terminal multiplexer with optimized settings
- **Enhanced Shell** - Bash configuration with useful aliases and git-aware prompt
- **bat** - Syntax highlighting for file previews

## 🚀 Quick Setup

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url> ~/Documents/dotfiles
   cd ~/Documents/dotfiles
   ```

2. **Run the bootstrap script:**
   ```bash
   ./bootstrap.sh
   ```

3. **Reload your shell:**
   ```bash
   source ~/.bashrc
   # or restart your terminal
   ```

## 🛠️ What the Bootstrap Script Does

### Package Installation
- ✅ **fzf** - Fuzzy finder for files and commands
- ✅ **bat** - Syntax highlighting cat replacement
- ✅ **tmux** - Terminal multiplexer
- ✅ **neovim** - Modern Vim-based editor

### Configuration Setup
- ✅ **Shell Configuration** - Enhanced bash with aliases and prompt
- ✅ **fzf Integration** - Key bindings and custom aliases
- ✅ **Tmux Configuration** - Optimized settings and key bindings
- ✅ **NvChad Setup** - Complete Neovim IDE configuration

## 🎯 Custom Aliases and Commands

### fzf Enhanced Aliases
```bash
vf          # Edit multiple files with fzf and syntax highlighting preview
cdf         # Navigate to any directory using fzf
kp          # Kill processes interactively with fzf
```

### Key Bindings
- `Ctrl-T` - Find files and paste path
- `Ctrl-R` - Search command history
- `Alt-C` - Change directory with fzf
- `**<TAB>` - Fuzzy completion for files/directories

### Git Shortcuts
```bash
gs          # git status
ga          # git add
gc          # git commit
gp          # git push
gl          # git log --oneline
gd          # git diff
```

## 📁 Repository Structure

```
dotfiles/
├── bootstrap.sh           # Main setup script
├── FZF_CHEATSHEET.md      # Comprehensive fzf guide
├── shell/
│   └── bashrc_additions   # Enhanced bash configuration
├── tmux/
│   └── tmux.conf          # Tmux configuration
├── nvim/                  # Neovim configurations (future)
├── config/                # General config files
└── git/                   # Git configurations (future)
```

## 🎨 fzf Usage Examples

### Basic Usage
```bash
# Edit files with preview
vf

# Navigate directories
cdf

# Search and edit multiple files
vim $(fzf -m --preview 'bat --color=always {}')

# Kill processes
kp
```

### Advanced fzf Commands
```bash
# Search file contents and edit
grep -r "search_term" . | fzf | cut -d: -f1 | xargs vim

# Git branch switching
git checkout $(git branch -a | fzf | sed 's/^[ *]*//')

# Process monitoring
ps aux | fzf
```

## 🔧 Tmux Configuration

### Key Features
- **Prefix**: Changed from `Ctrl-b` to `Ctrl-a`
- **Mouse Support**: Enabled for modern terminal usage
- **Vi Mode**: Vi-like key bindings for copy mode
- **Pane Management**: Intuitive split and navigation

### Key Bindings
```
Ctrl-a |    # Split window horizontally
Ctrl-a -    # Split window vertically
Ctrl-a h/j/k/l  # Navigate panes (vim-like)
Ctrl-a r    # Reload tmux config
```

## 🎭 Neovim with NvChad

### Features
- **NvChad**: Modern Neovim configuration framework
- **LSP Support**: Language server integration
- **Syntax Highlighting**: Tree-sitter based
- **Plugin Management**: Lazy.nvim plugin manager

### First Launch
After bootstrap, run `nvim` and NvChad will automatically:
1. Install required plugins
2. Set up language servers
3. Configure the IDE experience

## 🔍 fzf Cheat Sheet

See [FZF_CHEATSHEET.md](./FZF_CHEATSHEET.md) for a comprehensive guide including:
- All key bindings
- Advanced search syntax
- Integration examples
- Customization options

## 🎪 Customization

### Adding Your Own Configurations
1. Add files to appropriate directories (`shell/`, `tmux/`, etc.)
2. Update `bootstrap.sh` to include new setup functions
3. Source configurations in `shell/bashrc_additions`

### Environment Variables
```bash
# Customize fzf behavior
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Set default editor
export EDITOR=nvim
export VISUAL=nvim
```

## 🐛 Troubleshooting

### fzf Key Bindings Not Working
```bash
# Manually source fzf bindings
source /usr/share/doc/fzf/examples/key-bindings.bash
```

### Tmux Configuration Not Applied
```bash
# Reload tmux configuration
tmux source ~/.tmux.conf
```

### NvChad Installation Issues
```bash
# Remove and reinstall NvChad
rm -rf ~/.config/nvim
./bootstrap.sh  # Run setup again
```

## 🏗️ Requirements

- **OS**: Ubuntu/Debian (tested on Ubuntu 22.04+)
- **Shell**: Bash 4.0+
- **Git**: For cloning configurations
- **Internet**: For downloading packages and configurations

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Test your changes
4. Submit a pull request

## 📄 License

MIT License - feel free to use and modify as needed.

---

**Happy coding!** 🎉

# fzf Cheat Sheet

A comprehensive guide to using fzf (fuzzy finder) for efficient command-line navigation and file operations.

## 🚀 Quick Start

After running `./bootstrap.sh`, fzf will be installed and configured with key bindings.

## 📋 Basic Key Bindings

### Navigation
- `CTRL-K` / `CTRL-P` - Move cursor up
- `CTRL-J` / `CTRL-N` - Move cursor down
- `CTRL-U` - Page up
- `CTRL-D` - Page down

### Selection
- `Enter` - Select the item
- `CTRL-C` / `CTRL-G` / `ESC` - Exit without selection

### Multi-Selection Mode (`-m` flag)
- `TAB` - Mark/unmark item (toggle selection)
- `Shift-TAB` - Mark/unmark item (reverse toggle)
- `CTRL-A` - Select all
- `CTRL-D` - Deselect all

## ⌨️ Built-in Key Bindings

### File and Directory Navigation
- `CTRL-T` - Fuzzy find files and directories (paste path to command line)
- `CTRL-R` - Fuzzy find command history
- `ALT-C` - Fuzzy find directories and cd into selected one

### Completion Trigger
- `**<TAB>` - Fuzzy completion for files/directories
  - Example: `vim **<TAB>` - Find and complete file paths
  - Example: `cd **<TAB>` - Find and complete directory paths

## 🎯 Custom Aliases (from this dotfiles)

### File Operations
```bash
cdf         # Find and cd to directory
kp          # Kill process with fuzzy selection
```

### Usage Examples
```bash
# Edit multiple files with syntax highlighting preview
Ctrl+F

# Navigate to any directory quickly
cdf

# Kill processes interactively
kp
```

## 🔧 Environment Variables

### Default Options
```bash
FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
```

### File Preview (CTRL-T)
```bash
FZF_CTRL_T_OPTS="--preview 'bat --color=always {}' --preview-window=right:50%:wrap"
```

### History Preview (CTRL-R)
```bash
FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
```

## 💡 Advanced Usage Examples

### Basic fzf Commands
```bash
# Find files
fzf

# Multi-select files
fzf -m

# With preview
fzf --preview 'cat {}'

# With bat syntax highlighting
fzf --preview 'bat --color=always {}'
```

### Integration with Other Commands
```bash
# Edit files found by fzf
vim $(fzf)

# Remove files with confirmation
rm $(fzf -m)

# Copy files to directory
cp $(fzf -m) /path/to/destination/

# Open files in browser
firefox $(fzf)

# Search content and edit
grep -r "search_term" . | fzf | cut -d: -f1 | xargs vim
```

### Git Integration
```bash
# Checkout git branch
git checkout $(git branch -a | fzf | sed 's/^[ *]*//' | sed 's/remotes\/origin\///')

# Add files to git
git add $(git status -s | fzf -m | awk '{print $2}')

# Show git log and checkout commit
git checkout $(git log --oneline | fzf | awk '{print $1}')
```

### Process Management
```bash
# Kill process by name
ps aux | fzf | awk '{print $2}' | xargs kill

# Monitor specific processes
ps aux | grep $(ps aux | fzf | awk '{print $11}')
```

## 🎨 Preview Options

### File Previews
```bash
# Basic file preview
fzf --preview 'cat {}'

# Syntax highlighted preview (requires bat)
fzf --preview 'bat --color=always --style=numbers {}'

# Image preview (requires chafa/catimg)
fzf --preview 'chafa {}'

# Directory preview (requires tree)
fzf --preview 'tree -C {} | head -100'
```

### Preview Window Positions
```bash
--preview-window=right:50%     # Right side, 50% width
--preview-window=up:40%        # Top, 40% height
--preview-window=down:30%      # Bottom, 30% height
--preview-window=left:30%      # Left side, 30% width
```

## 🔍 Search Syntax

### Exact Match
```bash
'word      # Exact match for "word"
^word      # Match beginning with "word"
word$      # Match ending with "word"
```

### Fuzzy Search Modifiers
```bash
!word      # Exclude lines containing "word"
|          # OR operator: word1 | word2
&          # AND operator (space also works as AND)
```

### Examples
```bash
# Find files containing "config" but not "backup"
fzf -q "config !backup"

# Find files starting with "test"
fzf -q "^test"

# Find Python or JavaScript files
fzf -q "\.py$ | \.js$"
```

## 🛠️ Useful One-liners

### File System
```bash
# Find large files
find . -type f -exec du -h {} + | sort -rh | head -20 | fzf

# Find recent files
find . -type f -mtime -7 | fzf

# Find and open directories in file manager
xdg-open $(find . -type d | fzf)
```

### Development
```bash
# Find and edit configuration files
find /etc -name "*.conf" 2>/dev/null | fzf | xargs sudo vim

# Search and replace in files
ag -l "search_term" | fzf -m | xargs sed -i 's/search_term/replacement/g'

# Find and install packages (Ubuntu/Debian)
apt list 2>/dev/null | fzf | cut -d'/' -f1 | xargs sudo apt install
```

## 📦 Dependencies

### Required
- `fzf` - The main fuzzy finder

### Optional (for enhanced experience)
- `bat` - Syntax highlighting for file previews
- `tree` - Directory structure previews
- `ag` or `rg` - Fast text search
- `fd` - Fast file finder (alternative to find)

### Install Optional Dependencies
```bash
# Install bat for syntax highlighting
sudo apt install bat

# Install tree for directory previews
sudo apt install tree

# Install ripgrep for fast searching
sudo apt install ripgrep

# Install fd for fast file finding
sudo apt install fd-find
```

## 🚦 Tips and Tricks

1. **Performance**: Use `fd` or `ag` as the default command for better performance:
   ```bash
   export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
   ```

2. **Git Integration**: Add git-aware fzf commands to your workflow

3. **Multiple Selection**: Use `-m` flag for operations on multiple files

4. **Preview Everything**: Always use `--preview` for better context

5. **Custom Keybindings**: Bind fzf to custom keys for frequently used commands

6. **Combine Tools**: Chain fzf with other command-line tools for powerful workflows

---

## 🔗 Resources

- [fzf GitHub Repository](https://github.com/junegunn/fzf)
- [fzf Wiki](https://github.com/junegunn/fzf/wiki)
- [Advanced fzf Examples](https://github.com/junegunn/fzf/wiki/examples)

Happy fuzzy finding! 🎯
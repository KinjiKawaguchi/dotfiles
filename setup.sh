#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles Setup ==="
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# シンボリックリンクを作成する関数
link_file() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        echo "  [skip] $dest (already linked)"
    elif [ -e "$dest" ]; then
        echo "  [backup] $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
        ln -s "$src" "$dest"
        echo "  [link] $src -> $dest"
    else
        mkdir -p "$(dirname "$dest")"
        ln -s "$src" "$dest"
        echo "  [link] $src -> $dest"
    fi
}

echo "Creating symlinks..."

# Home directory dotfiles
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

# .config directory
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/.config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
link_file "$DOTFILES_DIR/.config/gh/config.yml" "$HOME/.config/gh/config.yml"

# SSH config
link_file "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"

# Claude Code
link_file "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
link_file "$DOTFILES_DIR/.claude/rules" "$HOME/.claude/rules"
link_file "$DOTFILES_DIR/.claude/commands" "$HOME/.claude/commands"

# VS Code (macOS)
if [ "$(uname)" = "Darwin" ]; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
    mkdir -p "$VSCODE_DIR"
    link_file "$DOTFILES_DIR/.config/Code/User/settings.json" "$VSCODE_DIR/settings.json"
    link_file "$DOTFILES_DIR/.config/Code/User/keybindings.json" "$VSCODE_DIR/keybindings.json"
fi

echo ""
echo "=== Homebrew ==="

# Homebrew install
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed"
fi

# Brewfile
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    echo "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"
else
    echo "Brewfile not found, skipping..."
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal"
echo "  2. Open Neovim and run :Lazy sync"
echo "  3. Sign in to Copilot with :Copilot auth"

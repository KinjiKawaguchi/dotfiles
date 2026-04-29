# ===========================================
# OS Detection
# ===========================================
case "$(uname -s)" in
  Darwin) IS_MACOS=true;  IS_LINUX=false ;;
  Linux)  IS_MACOS=false; IS_LINUX=true  ;;
esac

# ===========================================
# Homebrew (must be early for PATH availability)
# ===========================================
if $IS_MACOS; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ===========================================
# Powerlevel10k instant prompt (before any console output)
# ===========================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===========================================
# Oh My Zsh
# ===========================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git direnv)
source $ZSH/oh-my-zsh.sh

# ===========================================
# Environment Variables
# ===========================================
[[ -f ~/.secrets ]] && source ~/.secrets

export LANG='ja_JP.UTF-8'
export GPG_TTY=$(tty)

# Java
if $IS_MACOS; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null)
elif [ -d /usr/lib/jvm/default-java ]; then
  export JAVA_HOME=/usr/lib/jvm/default-java
fi
[ -n "$JAVA_HOME" ] && export PATH=$JAVA_HOME/bin:$PATH

# Go
export PATH=$PATH:$HOME/go/bin

# Python
if $IS_MACOS; then
  export PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:$PATH"
  export PATH="$HOME/Library/Python/3.12/bin:$PATH"
fi

# Rye
[ -f "$HOME/.rye/env" ] && source "$HOME/.rye/env"

# Bun
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Console Ninja
[ -d "$HOME/.console-ninja/.bin" ] && PATH="$HOME/.console-ninja/.bin:$PATH"

# Local bin
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# 1Password SSH Agent
# Linux 側で macOS 由来の壊れたソケットパスを継承している場合は明示的に unset
if $IS_MACOS; then
  export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
elif [ -S "$HOME/.1password/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
elif [ -n "$SSH_AUTH_SOCK" ] && [ ! -S "$SSH_AUTH_SOCK" ]; then
  unset SSH_AUTH_SOCK
fi

# ===========================================
# NVM
# ===========================================
if [ -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# ===========================================
# Google Cloud SDK
# ===========================================
_gcloud_sdk_dir=""
if [ -d "$HOME/google-cloud-sdk" ]; then
  _gcloud_sdk_dir="$HOME/google-cloud-sdk"
elif [ -d /usr/share/google-cloud-sdk ]; then
  _gcloud_sdk_dir="/usr/share/google-cloud-sdk"
fi
if [ -n "$_gcloud_sdk_dir" ]; then
  [ -f "$_gcloud_sdk_dir/path.zsh.inc" ] && . "$_gcloud_sdk_dir/path.zsh.inc"
  if [ -f "$_gcloud_sdk_dir/completion.zsh.inc" ]; then
    gcloud() {
      unset -f gcloud
      . "$_gcloud_sdk_dir/completion.zsh.inc"
      gcloud "$@"
    }
  fi
fi
unset _gcloud_sdk_dir

# ===========================================
# Angular CLI (lazy load)
# ===========================================
if command -v ng &>/dev/null; then
  ng() {
    unset -f ng
    source <(command ng completion script)
    ng "$@"
  }
fi

# ===========================================
# Bun completions (lazy load)
# ===========================================
if [ -s "$HOME/.bun/_bun" ]; then
  bun() {
    unset -f bun
    source "$HOME/.bun/_bun"
    bun "$@"
  }
fi

# ===========================================
# Aliases
# ===========================================
alias ..='cd ..'
alias activate='. .venv/bin/activate'
alias lg='lazygit'
alias cata="find . -type f -exec cat {} +"
alias vim='nvim'
alias vi='nvim'
alias cd='z'

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Vite+ bin (https://viteplus.dev)
[ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"

# ===========================================
# fzf
# ===========================================
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for _f in \
        /usr/share/doc/fzf/examples/key-bindings.zsh \
        /usr/share/fzf/key-bindings.zsh \
        /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
        "$HOME/.fzf.zsh"; do
      [ -f "$_f" ] && source "$_f" && break
    done
    for _f in \
        /usr/share/doc/fzf/examples/completion.zsh \
        /usr/share/fzf/completion.zsh \
        /opt/homebrew/opt/fzf/shell/completion.zsh; do
      [ -f "$_f" ] && source "$_f" && break
    done
    unset _f
  fi
fi

# ===========================================
# zoxide
# ===========================================
export _ZO_DOCTOR=0
eval "$(zoxide init zsh)"

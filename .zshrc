# ===========================================
# Oh My Zsh (must be configured before source)
# ===========================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git direnv)

# Powerlevel10k instant prompt (faster startup)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source $ZSH/oh-my-zsh.sh

# ===========================================
# Environment Variables
# ===========================================
export LANG='ja_JP.UTF-8'
export GPG_TTY=$(tty)

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH=$JAVA_HOME/bin:$PATH

# Go
export PATH=$PATH:$HOME/go/bin

# Python
export PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:$PATH"
export PATH="$HOME/Library/Python/3.12/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Cargo
source "$HOME/.cargo/env"

# Console Ninja
PATH=~/.console-ninja/.bin:$PATH

# Local bin
. "$HOME/.local/bin/env"

# 1Password SSH Agent
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# ===========================================
# NVM (lazy load - speeds up shell startup)
# ===========================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# ===========================================
# Google Cloud SDK
# ===========================================
if [ -f '/Users/KinjiKawaguchi/google-cloud-sdk/path.zsh.inc' ]; then
  . '/Users/KinjiKawaguchi/google-cloud-sdk/path.zsh.inc'
fi
# Lazy load gcloud completion
if [ -f '/Users/KinjiKawaguchi/google-cloud-sdk/completion.zsh.inc' ]; then
  gcloud() {
    unset -f gcloud
    . '/Users/KinjiKawaguchi/google-cloud-sdk/completion.zsh.inc'
    gcloud "$@"
  }
fi

# ===========================================
# Angular CLI (lazy load)
# ===========================================
ng() {
  unset -f ng
  source <(command ng completion script)
  ng "$@"
}

# ===========================================
# Bun completions (lazy load)
# ===========================================
if [ -s "/Users/KinjiKawaguchi/.bun/_bun" ]; then
  bun() {
    unset -f bun
    source "/Users/KinjiKawaguchi/.bun/_bun"
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
alias claude="/Users/KinjiKawaguchi/.claude/local/claude"
alias vim='nvim'
alias vi='nvim'

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

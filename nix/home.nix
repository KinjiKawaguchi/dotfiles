{ config, pkgs, ... }: let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in {
  home.stateVersion = "25.05";

  # ── Nix で管理するパッケージ（Brewfile から移行） ──────────────
  home.packages = with pkgs; [
    # CLI ツール
    bat
    cloc
    cowsay
    fd
    ffmpeg
    gh
    ghq
    gnused
    gnupg
    graphviz
    grpcui
    gtop
    jq
    ncdu
    fastfetch
    nmap
    ripgrep
    tree
    wget

    act
    docker
    docker-compose
    git
    git-lfs
    golangci-lint
    lazygit
    neovim
    pre-commit
    sshpass
    tmux
    uv
    pinentry_mac
    ookla-speedtest
    eslint
    lua-language-server
    prettier
    prettierd
    typescript-language-server
    tailwindcss-language-server
    nil

    nodejs_24
    pnpm
    yarn
    markdownlint-cli
    claude-code
    codex
  ];

  # ── dotfile シンボリックリンク ────────────────────────────────
  # mkOutOfStoreSymlink: Nix ストアを経由せず直接リンクするため
  # rebuild なしで設定ファイルの編集が即反映される
  home.file = {
    ".tmux.conf".source                        = link ".tmux.conf";
    ".p10k.zsh".source                         = link ".p10k.zsh";
    ".config/nvim".source                      = link "nvim";
    ".config/karabiner/karabiner.json".source   = link ".config/karabiner/karabiner.json";
    ".config/gh/config.yml".source             = link ".config/gh/config.yml";
    ".ssh/config".source                       = link ".ssh/config";

    # Git (OS 別設定: .gitconfig.os は macOS 用 .gitconfig.macos に向ける)
    ".gitconfig".source                          = link ".gitconfig";
    ".gitconfig.os".source                       = link ".gitconfig.macos";
    ".config/git/allowed_signers".source         = link ".config/git/allowed_signers";

    # Claude Code (~/.claude 配下の tracked な設定)
    ".claude/CLAUDE.md".source     = link ".claude/CLAUDE.md";
    ".claude/settings.json".source = link ".claude/settings.json";
    ".claude/statusline.sh".source = link ".claude/statusline.sh";
    ".claude/hooks".source         = link ".claude/hooks";
    ".claude/rules".source         = link ".claude/rules";
    ".claude/skills".source        = link ".claude/skills";
  };

  # ── Zsh ──────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      ".."       = "cd ..";
      activate   = ". .venv/bin/activate";
      lg         = "lazygit";
      vim        = "nvim";
      vi         = "nvim";
      cd         = "z";
    };

    sessionVariables = {
      LANG          = "ja_JP.UTF-8";
      SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      _ZO_DOCTOR    = "0";  # zoxide の初期化警告を抑制
    };

    initContent = ''
      # Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Homebrew (brews で入れたツールを PATH に通す)
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # Powerlevel10k theme
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # シェル展開が必要な環境変数
      export GPG_TTY="$(tty)"

      # Secrets
      [[ -f ~/.secrets ]] && source ~/.secrets

      # Java
      export JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null)
      [[ -n "$JAVA_HOME" ]] && export PATH="$JAVA_HOME/bin:$PATH"

      # Go
      export PATH="$PATH:$HOME/go/bin"

      # Bun
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"

      [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

      # Google Cloud SDK
      if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
        source "$HOME/google-cloud-sdk/path.zsh.inc"
      fi
    '';
  };

  # ── direnv ────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── fzf ───────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── zoxide ────────────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}

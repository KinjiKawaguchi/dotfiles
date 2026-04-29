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

    # Shell (programs.zsh は使わず .zshrc を symlink するため、ツールだけ提供)
    zsh
    fzf
    zoxide
    direnv
    nix-direnv
  ];

  # ── dotfile シンボリックリンク ────────────────────────────────
  # mkOutOfStoreSymlink: Nix ストアを経由せず直接リンクするため
  # rebuild なしで設定ファイルの編集が即反映される
  home.file = {
    ".zshrc".source                            = link ".zshrc";
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

  # zsh / oh-my-zsh / powerlevel10k / fzf / zoxide / direnv は home.file で
  # 管理する .zshrc から直接読み込む。programs.zsh / programs.fzf 等は使わない
  # （これらは home-manager が ~/.zshrc を生成してしまい symlink と競合するため）。
}

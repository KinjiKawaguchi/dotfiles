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

    # 開発ツール
    act
    docker
    docker-compose
    git-lfs
    lazygit
    neovim
    pre-commit
    tmux

    # 言語 / LSP
    buf
    dart
    eslint
    kotlin
    lua-language-server
    prettier
    typescript-language-server
    prettierd
    protobuf
    tailwindcss-language-server

    # Nix ツール
    nil
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

    # Claude Code (~/.claude 配下の tracked な設定)
    ".claude/CLAUDE.md".source     = link ".claude/CLAUDE.md";
    ".claude/settings.json".source = link ".claude/settings.json";
    ".claude/statusline.sh".source = link ".claude/statusline.sh";
    ".claude/hooks".source         = link ".claude/hooks";
    ".claude/rules".source         = link ".claude/rules";
    ".claude/skills".source        = link ".claude/skills";
  };

  # ── Git ───────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "KinjiKawaguchi";
        email = "kawakin0310@icloud.com";
        signingkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOKJoSSg4p0ozO6u8V+H0YzFYQ4lhfcVBMZGEfeGAcmy3P+o8F3Ql11JL3Lbm/8ymUco4Ln8INugbB1e5l38NoXjOZ5VPN7a9fnq34BjpKaq6NIIrU+vL6jHiXnQ6kk742FIayP7c6CdPvEnAvpCcnThgg5Ysg9/mzF8HHogvX+kfAlvRXNqEyIyXJS7XjVvF4NZOL6gCTbxB0gYubWUkQJaxUNB8+YqCqopetOujf7yuy+PRrcOSQfR7cce6TyvgDvzrBMpGkkfKhZ0lN+C7E2HFqMQBOeIEk/3JoHHqQum9mKq50Tk1V2dmPR5ppW7gNkOWPHCKAGxcYddafnQg9086eKIKv70l2tZjxl9WjqZG+cRwKRoJj27W+HhxoeOb6hHos7KZYURLICPJ5qpOVT+8D1p7cSD7L04XhJVmunY1vuD8FFibpirxm588RkunLYiYCUrMR1KmMtaA85y2qhssS+Xb/t2VhuvHWxH8kKcYjZ6s/ELfEGCk9CBdggME=";
      };
      core = {
        editor = "nvim";
        pager  = "less";
      };
      init.defaultBranch   = "main";
      push.autoSetupRemote = true;
      pull.rebase          = true;
      commit.gpgsign       = true;
      gpg.format           = "ssh";
      # 1Password の SSH 署名プログラム (macOS 固有)
      gpg.ssh.program      = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      filter."lfs" = {
        clean    = "git-lfs clean -- %f";
        smudge   = "git-lfs smudge -- %f";
        process  = "git-lfs filter-process";
        required = true;
      };
      # 空文字列で inherit した helper をリセットしてから gh を使う
      credential."https://github.com".helper      = [ "" "!gh auth git-credential" ];
      credential."https://gist.github.com".helper = [ "" "!gh auth git-credential" ];
    };
  };

  # ── Zsh ──────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

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

      # Cargo
      [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

      # NVM
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

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

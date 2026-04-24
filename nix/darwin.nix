{ pkgs, ... }: {
  # Determinate Systems installer を使用しているため nix-darwin の Nix 管理を無効化
  nix.enable = false;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "KinjiKawaguchi";
  users.knownUsers = [ "KinjiKawaguchi" ];
  users.users.KinjiKawaguchi = {
    uid = 501;
    home = "/Users/KinjiKawaguchi";
  };

  # Homebrew 連携（cask や Nix にないパッケージ用）
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
    };
    taps = [
      "dart-lang/dart"
      "hashicorp/tap"
      "heroku/brew"
      "teamookla/speedtest"
    ];
    brews = [
      "cabocha"
      "cocoapods"
      "envoy"
      "golangci-lint"
      "gradle"
      "heroku/brew/heroku"
      "mecab"
      "mecab-ipadic"
      "minicom"
      "mysql"
      "openapi-generator"
      "pgloader"
      "pinentry-mac"
      "postgresql@18"
      "pyenv"
      "python@3.10"
      "qemu"
      "rye"
      "sshpass"
      "teamookla/speedtest/speedtest"
    ];
    casks = [
      "1password-cli"
      "font-hack-nerd-font"
      "keycastr"
      "pgadmin4"
      "pycharm"
      "warp"
      "wireshark-app"
    ];
  };

  # macOS システム設定
  security.pam.services.sudo_local.touchIdAuth = true;

  # デフォルトシェル
  programs.zsh.enable = true;

  # nix-darwin のバージョン追跡用（初回設定時に固定し、以降変更しない）
  system.stateVersion = 6;
}

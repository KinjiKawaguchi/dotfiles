{ pkgs, ... }: {
  # Determinate Systems installer を使用しているため nix-darwin の Nix 管理を無効化
  nix.enable = false;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "KinjiKawaguchi";

  # Homebrew 連携（cask や Nix にないパッケージ用）
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
    };
    taps = [];
    # Nix にないもの / darwin 非対応 / バージョンの都合で Homebrew 側に残すもの
    brews = [
      "envoy" # nixpkgs は Linux 向けのみ
      "mysql" # nixpkgs は 8.4 LTS までで 9.x がない
    ];
    casks = [
      "1password-cli"
      "font-hack-nerd-font"
      "keycastr"
      "pgadmin4"
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

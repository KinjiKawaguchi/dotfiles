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

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    dock = {
      autohide = true;
      orientation = "right";
      tilesize = 40;
      magnification = false;
      largesize = 16;
      mineffect = "scale";
      show-recents = false;
      launchanim = false;
      wvous-br-corner = 14; # Quick Note
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      "com.apple.swipescrolldirection" = true;
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = true;
    };

    WindowManager.GloballyEnabled = false;
  };

  # デフォルトシェル
  programs.zsh.enable = true;

  # nix-darwin のバージョン追跡用（初回設定時に固定し、以降変更しない）
  system.stateVersion = 6;
}

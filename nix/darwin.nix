{ pkgs, username, ... }: {
  nix.enable = false;
  nixpkgs.config.allowUnfree = true;
  system.primaryUser = username;

  homebrew = {
    enable = builtins.getEnv "SKIP_BREW" != "1";
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
    };
    taps = [];
    masApps = {
      "Amphetamine" = 937984704;
      "Xcode" = 497799835;
    };
    # Nix にないもの / darwin 非対応 / バージョンの都合で Homebrew 側に残すもの
    brews = [
      "envoy" # nixpkgs は Linux 向けのみ
      "mysql" # nixpkgs は 8.4 LTS までで 9.x がない
    ];
    casks = [
      "1password"
      "1password-cli"
      "font-hack-nerd-font"
      "ghostty"
      "google-chrome"
      "google-drive"
      "google-japanese-ime"
      "karabiner-elements"
      "keycastr"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-word"
      "pgadmin4"
      "raycast"
      "setapp"
      "slack"
      "zoom"
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
      wvous-br-corner = 14;
      # nix/profiles/*.nix の項目は mkAfter でこの後ろに並べる
      persistent-apps = [
        "/Applications/Ghostty.app"
        "/Applications/Slack.app"
        "/System/Applications/iPhone Mirroring.app"
        "/Applications/zoom.us.app"
        "/Applications/Setapp/Session.app"
        "/Applications/Setapp/Godspeed.app"
      ];
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

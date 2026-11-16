# 個人 PC にだけ入れるアプリ。
# flake.nix の mkDarwin で profiles に渡したホストにだけ適用され、
# 各リストは nix/darwin.nix の共通定義に連結される。
{ lib, ... }: {
  homebrew = {
    casks = [
      "discord"
      "docker-desktop"
      "microsoft-outlook"
      "microsoft-teams"
      "onedrive"
      "spotify"
    ];
    masApps = {
      "Kindle" = 302584613;
      "Klack" = 6446206067;
      "LINE" = 539883307;
      "MenubarX" = 1575588022;
      "RunCat" = 1429033973;
    };
  };

  # mkAfter: Dock では共通分の後ろに並べる
  system.defaults.dock.persistent-apps = lib.mkAfter [
    "/Applications/Discord.app"
    "/Applications/Microsoft Teams.app"
    "/Applications/Microsoft Outlook.app"
    "/Applications/LINE.app"
    "/Applications/Spotify.app"
  ];
}

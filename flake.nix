{
  description = "KinjiKawaguchi's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, ... }: let
    username = "KinjiKawaguchi";

    # マシンごとに呼び出して darwinConfiguration を生成する
    mkDarwin = { hostname, system }: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./nix/darwin.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.${username} = import ./nix/home.nix;
        }
        {
          users.users.${username}.home = "/Users/${username}";
          networking.hostName = hostname;
        }
      ];
    };
  in {
    # ホスト追加は `make add-host` で自動挿入される
    darwinConfigurations = {
      "Kinjis-Macbook-180" = mkDarwin { hostname = "Kinjis-Macbook-180"; system = "aarch64-darwin"; };
      # NIX_HOSTS_END
    };
  };
}

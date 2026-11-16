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
    # profiles: nix/profiles/*.nix のうち、このホストに追加で適用するもの
    mkDarwin = { hostname, system, username, profiles ? [ ] }: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username; };
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
      ] ++ profiles;
    };
  in {
    darwinConfigurations = {
      "Kinjis-Macbook-180" = mkDarwin { hostname = "Kinjis-Macbook-180"; system = "aarch64-darwin"; username = "KinjiKawaguchi"; profiles = [ ./nix/profiles/personal.nix ]; };
      "kanolabnoMacBook-Pro" = mkDarwin { hostname = "kanolabnoMacBook-Pro"; system = "aarch64-darwin"; username = "kinjikawaguchi"; };
      # NIX_HOSTS_END
    };
  };
}

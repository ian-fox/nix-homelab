{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.modules.darwin."hosts/macbook" = {
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";
    imports =
      with config.flake.modules.darwin;
      [
        # Users
        ifox
      ]
      ++ [
        {
          home-manager.users.ifox = {
            imports = with config.flake.modules.homeManager; [
              # Modules
              devtools

              # Users
              ifox
            ];
            home.homeDirectory = "/Users/ifox";
          };
        }
      ];
  };

  flake.darwinConfigurations.macbook = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      inputs.home-manager.darwinModules.home-manager
      config.flake.modules.darwin."hosts/macbook"
    ];
  };

  flake.homeConfigurations."ifox@macbook" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    modules = with config.flake.modules.homeManager; [
      devtools
      ifox
    ];
  };
}

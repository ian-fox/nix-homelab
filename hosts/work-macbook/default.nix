{ inputs, ... }:
{
  flake.darwinConfigurations.work-macbook = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      ./configuration.nix
    ];
  };
}

{ inputs, ... }:
{
  flake.darwinConfigurations.work-macbook = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
    ];
  };
}

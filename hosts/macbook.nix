{
  config,
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

              # Users
              ifox
            ];
          };
        }
      ];
  };
}

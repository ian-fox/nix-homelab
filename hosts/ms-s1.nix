{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos."hosts/ms-s1" = _: {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    sops.defaultSopsFile = "${inputs.secrets}/secrets.yaml";
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    imports =
      with config.flake.modules.nixos;
      [
        sops

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
          };
        }
      ];
  };

  flake.nixosConfigurations.ms-s1 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      config.flake.modules.nixos."hosts/ms-s1"
    ];
  };

  flake.homeConfigurations."ifox@ms-s1" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = with config.flake.modules.homeManager; [
      devtools
      ifox
    ];
  };
}

{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos."hosts/forum" = _: {
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
            home.homeDirectory = "/home/ifox";
          };
        }
      ];
  };

  flake.nixosConfigurations.forum = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      config.flake.modules.nixos."hosts/forum"
    ];
  };
}

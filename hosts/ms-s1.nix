{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  flake.modules.nixos."hosts/ms-s1" = _: {
    imports = with config.flake.modules.nixos; [
      # Include the results of the hardware scan.
      # TODO: try facter instead
      ./ms-s1-hardware.nix
    ];

    boot = {
      # Use the systemd-boot EFI boot loader.
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      loader.grub.device = "nodev";

      # Use latest kernel.
      kernelPackages = pkgs.linuxPackages_latest;

      zfs.forceImportRoot = false;
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    nixpkgs.config.allowUnfree = true;

    # Copy the NixOS configuration file and link it from the resulting system
    # (/run/current-system/configuration.nix). This is useful in case you
    # accidentally delete configuration.nix.
    # TODO: is this helpful?
    system.copySystemConfiguration = true;

    networking = {
      hostName = "ms-s1";
      networkmanager.enable = true;
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    users.users.ifox = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      packages = with pkgs; [
        tree
      ];
      home = "/home/ifox";
    };
  };

  flake.nixosConfigurations.ms-s1 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.modules.nixos."hosts/ms-s1"
    ];
  };
}

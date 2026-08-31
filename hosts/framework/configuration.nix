{ lib, ... }:
{
  networking.hostName = "framework";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.enable = true;

  users.users.ifox = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsxaPgxP3IFVGWxiEoO3TP16zIdc5YVBrOdbtFNUNeT macbook"
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = lib.mkDefault "Europe/Oslo";

  # TODO: confirm this matches the NixOS release current at install time.
  # Do not change it after the first install.
  system.stateVersion = "26.05";
}

{ lib, pkgs, ... }:
{
  networking.hostName = "framework";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop environment
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # After rebuilding, enroll a finger with `fprintd-enroll` and check it
  # with `fprintd-verify`. Sudo/login/polkit accept it automatically.
  services.fprintd.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = lib.mkDefault "Europe/Oslo";

  system.stateVersion = "26.05";
}

{ lib, ... }:
{
  networking.hostName = "framework";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.firefox.enable = true;

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

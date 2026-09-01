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

  # TODO: move this to a module
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

  # Programs
  # TODO: move to modules for e.g. dev tools
  programs.firefox.enable = true;
  environment.systemPackages = [
    pkgs.git
    pkgs.emacs
    pkgs.vim
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = lib.mkDefault "Europe/Oslo";

  system.stateVersion = "26.05";
}

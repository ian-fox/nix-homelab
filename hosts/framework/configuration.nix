{ lib, pkgs, ... }:
{
  networking.hostName = "framework";
  networking.networkmanager.enable = true;

  homelab.persistence = {
    enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop environment
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  ## Turn off tap to click
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = false;
      clickMethod = "clickfinger";
    };
  };

  ## Plasma Wayland configures libinput through KWin rather than Xorg.
  home-manager.users.ifox.xdg.configFile."kcminputrc".text = ''
    [Libinput][Defaults][Touchpad]
    TapToClick=false
    ClickMethod=2
  '';

  # Fn is handled inside the Framework embedded controller, so it never
  # reaches Linux and cannot be swapped with a udev hwdb rule. Rewrite the
  # two entries in the Laptop 13 keyboard matrix instead:
  #
  #   physical Fn        (row 2, column 2)  -> left Ctrl (set-2 0x0014)
  #   physical left Ctrl (row 1, column 12) -> Fn        (set-2 0x00ff)
  #
  # The EC keeps these changes only at runtime, so reapply them every boot.
  systemd.services.framework-swap-fn-control = {
    description = "Swap the Framework keyboard's Fn and left Control keys";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    path = [ pkgs.framework-tool ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      framework_tool --remap-key 2 2 0x0014
      framework_tool --remap-key 1 12 0x00ff
    '';
  };

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

  zramSwap.enable = true;

  system.stateVersion = "26.05";
}

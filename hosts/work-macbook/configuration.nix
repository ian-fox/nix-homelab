{ pkgs, ... }:
{
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow sudo with touch ID
  security.pam.services.sudo_local.touchIdAuth = true;

  # Build binaries with rosetta
  nix.extraOptions = ''
    extra-platforms = x86_64-darwin aarch64-darwin
  '';

  environment.systemPackages = [
    pkgs.sl
  ];
}

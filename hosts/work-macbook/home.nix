{ pkgs, ... }:
{
  imports = [ ./karabiner.nix ];

  home = {
    username = "ifox";
    stateVersion = "26.05";

    packages = [
      pkgs.ripgrep
      pkgs.fd
      pkgs.colima
      pkgs.nushell
      pkgs.google-cloud-sdk
      pkgs.gh
    ];
  };

  # Colima uses this template to create a writable config for each new profile.
  home.file.".colima/_templates/default.yaml".source =
    pkgs.runCommand "colima-default.yaml"
      {
        nativeBuildInputs = [ pkgs.yq-go ];
      }
      ''
        # Keep upstream defaults for settings not explicitly overridden here.
        yq '.memory = 8 | .vmType = "vz" | .rosetta = true | .mountType = "virtiofs"' \
          ${pkgs.colima.src}/embedded/defaults/colima.yaml > "$out"
      '';
}

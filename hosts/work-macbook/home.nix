{ pkgs, ... }: {
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

  home.file.".colima/default/colima.yaml".text = ''
    memory: 8
    vmType: vz
    rosetta: true
  '';
}

{ pkgs, ... }: {
  home = {
    username = "ifox";
    stateVersion = "26.05";

    packages = [
      pkgs.ripgrep
      pkgs.fd
      pkgs.colima
    ];
  };

  home.file.".colima/default/colima.yaml".text = ''
    memory: 8
    vmType: vz
    rosetta: true
  '';
}

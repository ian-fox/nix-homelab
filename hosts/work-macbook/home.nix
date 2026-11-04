{ pkgs, ... }: {
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
}

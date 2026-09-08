{ pkgs, ... }:
{
  home.packages = [
    pkgs.deadnix
    pkgs.nixd
    pkgs.nixfmt
    pkgs.statix
  ];

  programs = {
    git.enable = true;
  };
}

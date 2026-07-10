{ ... }:
{
  flake.modules.homeManager.devtools = { pkgs, ... }: {
    home.packages = [ pkgs.ripgrep ];
  };
}

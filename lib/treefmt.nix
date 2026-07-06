{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    { config, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.mdformat.enable = true;
      };

      devshells.default = {
        packages = [ config.treefmt.build.wrapper ];
      };
    };
}

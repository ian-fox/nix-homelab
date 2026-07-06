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

        # Nix files
        programs.nixfmt.enable = true;
        programs.statix.enable = true;
        programs.deadnix.enable = true;

        # Markdown
        programs.mdformat.enable = true;
      };

      devshells.default = {
        packages = [ config.treefmt.build.wrapper ];
      };
    };
}

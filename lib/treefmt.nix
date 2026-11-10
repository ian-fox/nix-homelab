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

        # Markdown, including GitHub Flavored Markdown tables
        programs.mdformat = {
          enable = true;
          plugins = ps: [ ps.mdformat-gfm ];
        };
      };

      devshells.default = {
        packages = [ config.treefmt.build.wrapper ];
      };
    };
}

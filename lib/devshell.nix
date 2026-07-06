{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];

  flake.description = "This is a test";

  perSystem =
    { pkgs, ... }:
    {
      devshells.default = (
        { extraModulesPath, ... }@args:
        {
          # Ref: https://numtide.github.io/devshell/extending.html
          # Ref: https://github.com/numtide/devshell/tree/main/extra
          imports = [ "${extraModulesPath}/git/hooks.nix" ];

          packages = [ pkgs.cowsay ];

          git.hooks = {
            enable = true;
            pre-commit.text = "nix fmt && nix flake check";
          };
        }
      );
    };
}

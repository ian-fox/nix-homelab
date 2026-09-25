{
  description = "Ian's Nix Config";

  inputs = {
    # nixpkgs-weekly includes a dependency cooldown by default
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";

    # TODO: does it make any sense to have the inputs.nixpkgs-lib follow nixpkgs?
    flake-parts.url = "github:hercules-ci/flake-parts";

    # TODO: add some kind of automation so I don't have to manually declare nixpkgs.follows every time
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Provides the `facter.reportPath` NixOS module option consumed by
    # hardware detection reports from nixos-facter (the CLI itself ships in
    # nixpkgs as `pkgs.nixos-facter`, no separate input needed for that).
    facter.url = "github:nix-community/nixos-facter-modules";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The real secrets live in a separate, private repo so they're decoupled
    # from this (public) config repo. Defaults to the checked-in, unencrypted
    # placeholder below so plain `nix build`/`nix flake check` work with no
    # setup anywhere (including CI); real deploys must explicitly pass
    # `--override-input secrets git+ssh://git@github.com/<owner>/nix-secrets`.
    # See hosts/framework/README.md.
    secrets = {
      url = "path:./lib";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule

        ./lib/module.nix
        ./hosts/module.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          pkgs,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.default = pkgs.hello;
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}

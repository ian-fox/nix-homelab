# Architecture

## References

- [Dendritic design guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/main/README.md) by Doc-Steve
- [How I've been using flakes](https://dev.to/therobustroast/how-ive-been-using-nix-flakes-and-what-you-can-do-with-them-3g8h) by TheRobustRoast
- [Nix sops flake template](https://github.com/sshine/nix-sops-flake-template)
- [Lefthook and treefmt with nix](https://simonshine.dk/articles/lefthook-treefmt-direnv-nix/)

## General Design

- Explicitly import modules over using magic glue like import-tree, one less dependency to worry about.
- Most things should be dendritic, but top-level inputs will be in the root flake so that they can be set up with `inputs.nixpkgs.follows` and to keep the number of direct dependencies visible.

## Structure

- [lib](../lib/): Code related to developing the flake. Checks, formatters, etc.
- [hosts](../hosts/): NixOS configurations, one directory per machine.
- [modules](../modules/): Reusable NixOS and Home Manager modules shared by hosts.

## Shared modules

### NixOS

- [ifox.nix](../modules/nixos/ifox.nix): defines the `ifox` NixOS user and attaches Home Manager configuration.
- [persistence.nix](../modules/nixos/persistence.nix): Configures persistence for the erase-your-darlings pattern

### Home manager

- [dev-tools.nix](../modules/home-manager/dev-tools.nix) development tools
- [firefox.nix](../modules/home-manager/firefox.nix) firefox defaults, including the ability to swap keybinds to match the muscle memory from using CMD on a mac

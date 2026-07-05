# Architecture

## References

- [Dendritic design guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/main/README.md) by Doc-Steve
- [How I've been using flakes](https://dev.to/therobustroast/how-ive-been-using-nix-flakes-and-what-you-can-do-with-them-3g8h) by TheRobustRoast
- [Nix sops flake template](https://github.com/sshine/nix-sops-flake-template)
- [Lefthook and treefmt with nix](https://simonshine.dk/articles/lefthook-treefmt-direnv-nix/)

## General Design

- Explicitly import modules over using magic glue like import-tree, to make following what's included from where easier.
- Most things should be dendritic, but top-level inputs will be in the root flake so that they can be set up with `inputs.nixpkgs.follows`

## Structure

- [lib](../lib/): Code related to developing the flake. Checks, formatters, etc.

# Config

Documenting my journey to setting up a home-lab fully managed by [nix](https://nixos.org/)

## Documents

- [Design Doc](./docs/DESIGN.md)
- [Architecture](./docs/ARCHITECTURE.md)

## Developing

A [devshell](./lib/devshell.nix) with git hooks is provided for use with `nix develop`. This ensures `nix fmt` and `nix flake check` are run before a commit.

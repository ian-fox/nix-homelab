# Config

Documenting my journey to setting up a home-lab fully managed by [nix](https://nixos.org/)

## Goals

* Try out the [dendritic pattern](https://github.com/mightyiam/dendritic)
* Have no [ephemeral state](https://grahamc.com/blog/erase-your-darlings/)
* Have networking set up to be able to SSH around between the machines
* Configure a server with a variety of workloads as code, sandboxed with [incus](github.com/lxc/incus)
  * Local LLM inference
  * Git forge+CI tooling
  * Backups
  * Metrics
  * Still able to boot in as a desktop environment on occasion if I want to use the GPU for gaming
  * Other services in the future like immich, unified logging
* Configure my personal settings across various other machines with home manager and nix-darwin
* Stick to libraries that are somewhat popular (I'll leave the bleeding-edge libraries to people who know what they're doing)
* Document all this in a (series of) blog posts

## Eventual Goals

* Secure boot

## References

* [Doc-Steve's guide](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/main/README.md)
* [Blog post by Callum](https://callumwong.com/posts/2026-homelab-reno)
* [Flake Parts library](https://flake.parts/)


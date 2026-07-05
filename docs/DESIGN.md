# Nix Homelab Design Doc

## Objective

Define a declarative home-lab setup for developing, gaming, experimenting, and self-hosting apps.

## Background

I recently found a good deal on one of those 128GB mini-AI boxes, and for a while have been meaning to play around with local models. Separately, I've also been meaning to get more into self-hosting and move away from things like google photos.

## Related Documents

* [Refactoring English's post on design docs](https://refactoringenglish.com/excerpts/write-an-effective-design-doc)
* [Nix homelab post by Callum](https://callumwong.com/posts/2026-homelab-reno)
* [Nix homelab post by Bas](https://www.nijho.lt/post/proxmox-to-nixos/)
* [Secrets management](https://unmovedcentre.com/posts/secrets-management/)
* [Incus on Nix](https://luka.korosec.cc/posts/2025/09/declarative-incus-on-nixos-with-sso/)

## Goals

* Define all configuration as code; it should be minimally painful to re-provision a machine from scratch.
  * This includes having [no ephemeral state](https://grahamc.com/blog/erase-your-darlings/).
* Allow for self-hosting a variety of applications such as git forges, media servers, etc.
  * These should be available over the internet (behind suitable auth), not just on the local network.
* Make logs and metrics available to diagnose problems.
* Automate backups, and periodically test them.
* Have a high standard of documentation which is kept up-to-date.
* Make use of type-checking, linters, tests, etc. to avoid breaking changes and keep a high standard of code quality.
* Maintain the ability to boot into the mini-PC as a desktop so I can use the graphics card to play games on occasion.

## Non-goals

* High availability: I don't need five 9s of uptime. Services should be somewhat reliable, but I (at least for now) am happy to have single instances without failover/redundancy for most things.
* Extending to all devices: eventually using this to configure things like my steam deck would be neat, but that is out of scope for now.
* Specific self-hosted services beyond what's described in the infrastructure section below. E.g. eventually I would like to set up a git forge and local CI tooling, but GitHub will work fine for now.
* A specific delivery timeline; this is hobby work done as availability permits.
* Making modules that can be imported by others; I'll leave that for future work once I'm more familiar with flake-parts, for now I just want to get something that works in one repo.

## Interfaces

todo: something about virtual network access

## Dependencies/Infrastructure

* Primary language: [nix](https://nixos.org/)
  * A good fit for the declarative goals with a strong ecosystem and examples of similar setups in the wild.
  * Third-party library: [flake-parts](https://flake.parts) to support trying out the [dendritic pattern](https://github.com/mightyiam/dendritic)
  * Aim to avoid critical dependencies on more niche libraries than flake parts - I'm sure they're great, but depending on something maintained by one person is not ideal.
  * To start I'll try with nixpkgs unstable. If things break too frequently I'll move back to stable channels.
* Virtualization: [incus](https://github.com/lxc/incus)
  * Handles both containers and virtual machines, libraries exist for managing services with nix.
  * For durability, plan to use systemd units over k8s because of lower overhead.
* Logging/Monitoring: Victoriametrics stack
  * Self-hostable, follows OpenTelemetry standards
* Secret management: sops-nix

## Alternatives Considered

### Base OS

* Fedora suite of immutable distros: Mature and well-supported, but more work to do everything declaratively.
* Incus OS: works for the self-hosting different services bit, but looks like it would be annoying to try to use the machine it's on as an actual desktop.

## Security

* Services should run in isolated containers or VMs.
* SSH should enforce key-based auth, no passwords.

## Open Issues

### Access Control

For remote access, [tailscale](https://tailscale.com/) seem like a likely contender, but when the time comes I'll look into what alternatives there are as well. Similarly for a reverse proxy when looking at exposing services to the internet.

### Power Saver

It should be possible to have machines hosting services be in a low-power state when I'm not using them, and wake up to do scheduled tasks or when they receive traffic. This is both for saving energy, and so that the fan on the machine under my desk isn't making a bunch of noise at all hours. I'm not sure yet how difficult this will be to set up.

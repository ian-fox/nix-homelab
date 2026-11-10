# framework

Framework 13 Pro (Intel) laptop.

## Layout

- LUKS-encrypted disk (`/dev/nvme0n1`), Btrfs inside with subvolumes for
  `/` (root), `/nix`, `/persist`, and a reserved `/.swapvol`. See
  [disko.nix](./disko.nix).
- Impermanence: root is wiped back to empty on every boot. Anything meant to
  survive a reboot must be declared in [persistence.nix](./persistence.nix)
  under `environment.persistence."/persist"` — config doesn't need an entry
  since it's rebuilt from this flake, but things like media libraries do.
- Hardware detection is via [nixos-facter](https://github.com/nix-community/nixos-facter)
  rather than a hand-written `hardware-configuration.nix`. `facter.json` in
  this directory starts as an empty placeholder and gets overwritten with a
  real report during the first deploy (see below) — commit the real one
  afterwards.
- Secrets ([sops.nix](./sops.nix)): encrypted secrets live in a separate,
  private `nix-secrets` repo rather than in this one, so this config repo
  stays decoupled from (and can remain public independent of) the secrets.
  The public `nixosConfigurations.framework` defaults to the unencrypted
  stub at [`lib/secrets.yaml`](../../lib/secrets.yaml), so builds and CI
  need no access to private secrets. Deployments with real secrets use a
  [private deployment flake](#private-deployment-flake) that imports
  `nixosModules.framework` and overrides `sops.defaultSopsFile`.
  Decryption on the laptop itself uses the host's SSH key as the sops age
  key (`sops.age.sshKeyPaths`), which works here since that key is already
  persisted across reboots (see persistence.nix).

## Deploying

For the initial installation before adding secrets, run this from the public
config repo on a machine that can reach the laptop over SSH (e.g. booted into
a NixOS live installer):

```console
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-facter ./hosts/framework/facter.json \
  --flake .#framework \
  --build-on-remote \
  --target-host root@<laptop-ip>
```

`--build-on-remote` builds the system closure on the laptop itself rather
than on the controller machine — needed whenever the controller can't
natively build `x86_64-linux` (e.g. deploying from an aarch64 Mac, which
can't build Linux derivations at all without a configured builder).

This detects hardware with nixos-facter, writes `facter.json` locally,
partitions the disk with disko (prompts for the LUKS password), and installs.
Commit the regenerated `facter.json` afterwards. Re-run the same command
(without wiping) any time the hardware changes and you want to refresh it.

### Private deployment flake

Put a `flake.nix` next to the encrypted `secrets.yaml` in the private
`nix-secrets` repo:

```nix
{
  inputs = {
    homelab.url = "github:ian-fox/nix-homelab";
    nixpkgs.follows = "homelab/nixpkgs";
  };

  outputs = { homelab, nixpkgs, ... }: {
    nixosConfigurations.framework = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        homelab.nixosModules.framework
        {
          sops.defaultSopsFile = ./secrets.yaml;
          sops.secrets."wifi-psk" = { };
          # Configure the service consuming the secret here too.
        }
      ];
    };
  };
}
```

The public module uses `lib.mkDefault` for `sops.defaultSopsFile`, so this
assignment selects the private encrypted file. Keep secret declarations and
their consumers in this private flake; the public configuration continues to
evaluate with its stub. Both flakes use the same nixpkgs input.

Stage new `flake.nix` and encrypted `secrets.yaml` files with Git before
evaluating the private flake, then run `nix flake lock` there and commit the
resulting `flake.lock`. After changing the public host configuration, run
`nix flake update homelab` in the private repo to pick up those changes and
commit its updated lock file.

Run subsequent deployments from this private repo using `--flake .#framework`.
The public flake has no `secrets` input; `--override-input secrets ...` does
not select a different SOPS file.

### Adding the first secret

sops-nix decrypts using the host's SSH key, which doesn't exist until the
host has booted once — so the first secret can't be encrypted until after
the initial install above:

1. Boot the freshly-installed host, then copy its generated
   `/etc/ssh/ssh_host_ed25519_key.pub` to `ssh_host_ed25519_key.pub` on the
   controller machine.
1. Convert it to an age recipient:
   `nix run github:Mic92/ssh-to-age -- -i ssh_host_ed25519_key.pub`.
1. In the `nix-secrets` repo, add that age key as a recipient (alongside
   your own personal key, so you can still edit it yourself) and encrypt
   the secret into `secrets.yaml` with `sops`.
1. Set up the private deployment flake above, declare the secret and wire it
   into whatever consumes it there, then rebuild from the private repo:
   ```console
   nixos-rebuild switch --target-host root@<laptop-ip> --build-host root@<laptop-ip> \
     --flake .#framework
   ```
   (`--build-host` matching `--target-host` builds on the laptop itself —
   same reasoning as `--build-on-remote` above.)

## Not yet wired up

- **Hibernation**: swap is zram-only for now. The `/.swapvol` subvolume is
  reserved so enabling a disk-backed hibernation swapfile later is just
  adding `swap.swapfile.size = "<>= RAM size>";` to that subvolume in
  disko.nix, plus `boot.resumeDevice` / a `resume_offset` kernel param in
  configuration.nix — no repartitioning needed.
- **Actual secrets**: sops.nix is wired up, but the private `nix-secrets`
  repo and its `secrets.yaml` don't exist yet, and no `sops.secrets.*` are
  declared anywhere — there's nothing to encrypt yet (wifi PSKs, tokens,
  etc. will land here later). Note: avoid the
  `fileSystems."/etc/ssh".neededForBoot = true;` variant some sops-nix docs
  suggest for the age key path — it's currently broken under impermanence's
  systemd.mounts backend
  ([impermanence#294](https://github.com/nix-community/impermanence/issues/294)).

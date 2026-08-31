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
  The `secrets` flake input defaults to the unencrypted stub at
  [`lib/secrets.yaml`](../../lib/secrets.yaml), so plain `nix build`/
  `nix flake check` work with no setup on any machine (this is also what
  lets CI pass with no access to real secrets at all). There's
  deliberately no "local checkout" default pointing at a fixed path like
  `/etc/nix-secrets` — Nix's `git+file` fetcher refuses to resolve through
  a symlinked path component, and `/etc` itself is a symlink on macOS, so
  that pattern breaks `nix flake lock`/`nix flake check` on any Mac. Real
  deploys instead always pass the real repo explicitly:
  `--override-input secrets git+ssh://git@github.com/<owner>/nix-secrets`.
  Decryption on the laptop itself uses the host's SSH key as the sops age
  key (`sops.age.sshKeyPaths`), which works here since that key is already
  persisted across reboots (see persistence.nix).

## Deploying

From a machine that can reach the laptop over SSH (e.g. booted into a NixOS
live installer):

```console
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-facter ./hosts/framework/facter.json \
  --flake .#framework \
  --target-host root@<laptop-ip>
```

This detects hardware with nixos-facter, writes `facter.json` locally,
partitions the disk with disko (prompts for the LUKS password), and installs.
Commit the regenerated `facter.json` afterwards. Re-run the same command
(without wiping) any time the hardware changes and you want to refresh it.

### Adding the first secret

sops-nix decrypts using the host's SSH key, which doesn't exist until the
host has booted once — so the first secret can't be encrypted until after
the initial install above:

1. Boot the freshly-installed host, then read its generated host key:
   `ssh-keyscan -t ed25519 <laptop-ip>` (or read
   `/etc/ssh/ssh_host_ed25519_key.pub` directly on the box).
1. Convert it to an age recipient:
   `nix run github:Mic92/ssh-to-age -- -i ssh_host_ed25519_key.pub`.
1. In the `nix-secrets` repo, add that age key as a recipient (alongside
   your own personal key, so you can still edit it yourself) and encrypt
   the secret into `secrets.yaml` with `sops`.
1. Declare it in [sops.nix](./sops.nix) (e.g. `sops.secrets."wifi-psk" = { };`), wire it into whatever consumes it, and rebuild with the real
   secrets repo overridden in:
   ```console
   nixos-rebuild switch --target-host root@<laptop-ip> --flake .#framework \
     --override-input secrets git+ssh://git@github.com/<owner>/nix-secrets
   ```

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

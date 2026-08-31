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

## Not yet wired up

- **Hibernation**: swap is zram-only for now. The `/.swapvol` subvolume is
  reserved so enabling a disk-backed hibernation swapfile later is just
  adding `swap.swapfile.size = "<>= RAM size>";` to that subvolume in
  disko.nix, plus `boot.resumeDevice` / a `resume_offset` kernel param in
  configuration.nix — no repartitioning needed.
- **sops-nix**: added as a flake input, not wired into any module yet since
  there's nothing to encrypt. When there is (wifi PSKs, tokens, etc.), the
  usual pattern is `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key"
  ];`, which works here since the host SSH keys are already persisted in
  persistence.nix. Avoid the `fileSystems."/etc/ssh".neededForBoot = true;`
  variant some sops-nix docs suggest — it's currently broken under
  impermanence's systemd.mounts backend
  ([impermanence#294](https://github.com/nix-community/impermanence/issues/294)).

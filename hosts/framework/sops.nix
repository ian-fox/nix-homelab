{ lib, ... }:
{
  # Stub for public CI
  sops.defaultSopsFile = lib.mkDefault ../../lib/secrets.yaml;

  # Host SSH key doubles as the sops age key, avoiding a separate key to
  # manage. It's persisted across reboots, see ./persistence.nix.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}

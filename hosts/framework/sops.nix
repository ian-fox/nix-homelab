{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = "${inputs.secrets}/secrets.yaml";
  # Host SSH key doubles as the sops age key, avoiding a separate key to
  # manage. It's persisted across reboots, see ./persistence.nix.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}

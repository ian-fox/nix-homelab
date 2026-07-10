{ inputs, ... }:
{
  flake.modules.nixos.sops = _: {
    imports = [ inputs.sops-nix.nixosModules.sops ];
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  flake.modules.darwin.sops = _: {
    imports = [ inputs.sops-nix.darwinModules.sops ];
    sops.age.keyFile = "/etc/nix-secrets/age-key.txt";
  };
}

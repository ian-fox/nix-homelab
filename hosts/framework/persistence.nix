_: {
  # Erase-your-darlings: the root subvolume is deleted and recreated empty on
  # every boot, before it's mounted. Nothing on it survives a reboot unless
  # it's declared below under environment.persistence. The NixOS config
  # itself doesn't need to survive since it's rebuilt from the flake.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.rollback-root = {
    description = "Roll back the root subvolume to an empty state";
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@cryptroot.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/cryptroot /mnt
      btrfs subvolume delete /mnt/root
      btrfs subvolume create /mnt/root
      umount /mnt
    '';
  };

  environment.persistence."/persist" = {
    persistentStoragePath = "/persist";
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      {
        file = "/etc/ssh/ssh_host_ed25519_key.pub";
        method = "symlink";
      }
      "/etc/ssh/ssh_host_rsa_key"
      {
        file = "/etc/ssh/ssh_host_rsa_key.pub";
        method = "symlink";
      }
    ];
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
    ];
    # Add more here as you find state worth keeping (e.g. media libraries) -
    # anything not listed is wiped on reboot, config doesn't need an entry.
    users.ifox = {
      directories = [
        "Downloads"
        "Documents"
        "Pictures"
        "Videos"
        "Music"
        ".ssh"
      ];
    };
  };

  zramSwap.enable = true;
}

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.persistence;

  persistenceEntryType = lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything);
  userPersistenceType = lib.types.submodule {
    options = {
      files = lib.mkOption {
        type = lib.types.listOf persistenceEntryType;
        default = [ ];
        description = "Files to persist relative to the user's home directory.";
      };

      directories = lib.mkOption {
        type = lib.types.listOf persistenceEntryType;
        default = [ ];
        description = "Directories to persist relative to the user's home directory.";
      };
    };
  };

  persistCheck = pkgs.writeShellApplication {
    name = "persist-check";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      if (( $# != 1 )); then
        echo "Usage: persist-check PATH" >&2
        exit 2
      fi

      persistence_checked_path="$(realpath -m -- "$1")"
      if ! persistence_fsroot="$(findmnt --noheadings --raw --first-only \
        --target "$persistence_checked_path" --output FSROOT)"; then
        echo "persist-check: cannot find the filesystem containing $persistence_checked_path" >&2
        exit 2
      fi

      persistence_storage_path=${lib.escapeShellArg cfg.persistentStoragePath}
      if [[ "$persistence_checked_path" == "$persistence_storage_path" \
        || "$persistence_checked_path" == "$persistence_storage_path"/* \
        || "$persistence_fsroot" == "$persistence_storage_path" \
        || "$persistence_fsroot" == "$persistence_storage_path"/* ]]; then
        printf 'persisted: %s [%s]\n' "$persistence_checked_path" "$persistence_fsroot"
        exit 0
      fi

      printf 'ephemeral: %s [%s]\n' "$persistence_checked_path" "$persistence_fsroot"
      exit 1
    '';
  };
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.homelab.persistence = {
    enable = lib.mkEnableOption "an ephemeral root backed by Impermanence";

    persistentStoragePath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Mount point that stores persistent files and directories.";
    };

    files = lib.mkOption {
      type = lib.types.listOf persistenceEntryType;
      default = [ ];
      description = ''
        Absolute file paths persisted from the root filesystem. Definitions
        add to the module defaults; use lib.mkForce to replace them.
      '';
    };

    directories = lib.mkOption {
      type = lib.types.listOf persistenceEntryType;
      default = [ ];
      description = ''
        Absolute directory paths persisted from the root filesystem.
        Definitions add to the module defaults; use lib.mkForce to replace
        them.
      '';
    };

    users = lib.mkOption {
      type = lib.types.attrsOf userPersistenceType;
      default = { };
      description = ''
        Files and directories persisted relative to each user's home
        directory. Definitions add to the module defaults; use lib.mkForce
        on a list or user attribute to replace them.
      '';
    };

    rollbackRoot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to recreate the root Btrfs subvolume on every boot.";
      };

      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/mapper/cryptroot";
        description = "Btrfs device containing the ephemeral root subvolume.";
      };

      subvolume = lib.mkOption {
        type = lib.types.strMatching "[[:alnum:]_.-]+";
        default = "root";
        description = "Name of the Btrfs subvolume mounted at the filesystem root.";
      };

      after = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "systemd-cryptsetup@cryptroot.service" ];
        description = "Initrd units that must start before root is rolled back.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.persistentStoragePath && cfg.persistentStoragePath != "/";
        message = "homelab.persistence.persistentStoragePath must be an absolute path other than /.";
      }
    ];

    # These are definitions rather than option defaults so other modules can
    # append normally. A caller can replace any list with lib.mkForce.
    homelab.persistence = {
      files = lib.mkBefore [
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

      directories = lib.mkBefore [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
      ];

      users.ifox.directories = lib.mkBefore [
        "Downloads"
        "Documents"
        "Pictures"
        "Videos"
        "Music"
        ".ssh"
        # Desktop and application state, plus caches that are expensive to
        # regenerate after every reboot.
        ".config"
        ".local/share"
        ".cache"
      ];
    };

    fileSystems.${cfg.persistentStoragePath}.neededForBoot = true;

    boot.initrd.systemd = {
      enable = true;
      services.rollback-root = lib.mkIf cfg.rollbackRoot.enable {
        description = "Roll back the root subvolume to an empty state";
        wantedBy = [ "initrd.target" ];
        after = cfg.rollbackRoot.after;
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir -p /mnt
          mount -o subvol=/ ${lib.escapeShellArg cfg.rollbackRoot.device} /mnt
          btrfs subvolume delete ${lib.escapeShellArg "/mnt/${cfg.rollbackRoot.subvolume}"}
          btrfs subvolume create ${lib.escapeShellArg "/mnt/${cfg.rollbackRoot.subvolume}"}
          umount /mnt
        '';
      };
    };

    environment.persistence.${cfg.persistentStoragePath} = {
      inherit (cfg) persistentStoragePath;
      inherit (cfg) files directories users;
    };

    environment.systemPackages = [ persistCheck ];
  };
}

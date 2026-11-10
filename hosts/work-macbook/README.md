# work-macbook

## Colima

Home Manager manages Colima's [default template](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#setting-the-default-config)
at `~/.colima/_templates/default.yaml`. It keeps the packaged Colima defaults and
sets 8 GiB of memory, the `vz` VM type, and Rosetta support for new profiles.
Colima creates and owns each profile's writable `colima.yaml` on first start;
rebuilds and template changes leave existing profile configurations alone.

Change defaults in [home.nix](./home.nix). Use `colima start --edit` to change an
existing profile. The `colima template` command edits the template managed by
Nix, so make template changes in the flake instead.

## Firefox tab shortcuts

Karabiner-Elements is installed by nix-darwin through Homebrew, and
[karabiner.nix](./karabiner.nix) manages its selected profile through Home Manager.
While Firefox is focused, either Option key works with these shortcuts:

| Shortcut     | Sent to Firefox   | Action       |
| ------------ | ----------------- | ------------ |
| Option+Left  | Control+Shift+Tab | Previous tab |
| Option+Right | Control+Tab       | Next tab     |

On first launch, follow Karabiner-Elements' setup prompts to allow input
monitoring, background services, and the virtual keyboard system extension in
macOS System Settings. These permissions require local approval.

The entire `~/.config/karabiner` directory is managed by Nix and is read-only;
make configuration changes in the flake. If you already have a Karabiner
configuration, move that directory aside before the first rebuild and merge any
rules you want to keep into the Nix configuration. Home Manager will refuse to
overwrite an existing unmanaged configuration.

Home Manager restarts Karabiner's configuration watcher when these rules change,
if the service is already running. Karabiner requires a
[directory symlink rather than a file symlink](https://karabiner-elements.pqrs.org/docs/manual/misc/configuration-file-path/)
for configuration monitoring.

For adjacent tabs, turn off Firefox's **Ctrl+Tab cycles through tabs in recently
used order** in Settings > General > Tabs. The remap applies in the address bar
and Firefox settings as well as web pages. Additional held modifiers other than
Caps Lock do not match these rules.

To verify, open three Firefox tabs and test both shortcuts, including with the
address bar focused. Check another app to confirm Option+Left/Right retains its
usual behavior there.

## Linux equivalent

[xremap](https://github.com/xremap/xremap) supports the same app-specific remap on
Linux, including Wayland. Its [NixOS module](https://github.com/xremap/nix-flake)
can express the rules as:

```nix
services.xremap.config.keymap = [
  {
    name = "Firefox tab navigation";
    application.only = [ "firefox" ];
    exact_match = true;
    remap = {
      "Alt-Left" = "Ctrl-Shift-Tab";
      "Alt-Right" = "Ctrl-Tab";
    };
  }
];
```

This is a configuration example, not enabled on `framework`: that host has no
desktop session configured yet. Enabling it requires importing xremap's NixOS
module and setting up application detection for the chosen desktop (GNOME and
KDE Wayland need desktop extensions). Confirm Firefox's application identifier
for that session; it can differ from `firefox`. On Linux these bindings replace
Firefox's Alt+Left/Right history navigation.

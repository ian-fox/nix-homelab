# work-macbook

## Kitty

Homebrew installs Kitty; Home Manager generates `~/.config/kitty/kitty.conf`.
Edit settings in [home.nix](./home.nix) and the Blazer theme colors in
[kitty/current-theme.conf](./kitty/current-theme.conf), which are included in
the generated config. Only active settings from the original config are kept;
Kitty supplies the remaining defaults and handles its own shell integration.

nix-darwin installs 0xProto Nerd Font; Kitty uses its monospace variant
at 15 points. Highlighting text leaves the clipboard unchanged; **Cmd+C** copies
the selection. The config opens links with
**Cmd+Click** even when an application grabs the mouse, includes colons in
double-click word selection, places separator-style tabs at the top, and sends
the left Option key as Alt.

Before the first rebuild, back up and move the existing
`~/.config/kitty/kitty.conf` out of the way so Home Manager can create its
symlink. Apply with `sudo darwin-rebuild switch --flake .#work-macbook` from the
repository root, then restart Kitty to apply the Option key setting. Make
future settings and theme changes in the flake.

### Trying settings and themes

The managed config is a symlink into the read-only Nix store. For experiments,
copy the config directory into a writable temporary directory and launch a
separate Kitty instance:

```sh
kitty_trial=$(mktemp -d)
cp -RL "$HOME/.config/kitty/." "$kitty_trial/"
chmod -R u+w "$kitty_trial"
KITTY_CONFIG_DIRECTORY="$kitty_trial" kitty
```

Use **Cmd+,** or `kitten themes` inside that instance. If running the theme
picker from the original terminal, use
`KITTY_CONFIG_DIRECTORY="$kitty_trial" kitten themes`. Setting the config
directory also redirects theme files and tools; passing only `kitty --config`
does not redirect every tool's writes.

After experimenting, compare the settings:

```sh
diff -u "$HOME/.config/kitty/kitty.conf" "$kitty_trial/kitty.conf"
```

Port settings you want to keep into `programs.kitty` in `home.nix`. If you
selected a theme, copy its generated `$kitty_trial/current-theme.conf` into
`kitty/current-theme.conf` in this directory. Rebuild to apply the changes to
your normal Kitty sessions; experiments stay in the temporary directory.

## Zellij

Home Manager installs Zellij and manages `~/.config/zellij/config.kdl` and
`~/.config/zellij/plugins/tab-mode-indices.wasm`. Edit the configuration in
[zellij/config.kdl](./zellij/config.kdl); Home Manager replaces `@zellijConfigDir@`
with the user's Zellij config directory. The custom plugin temporarily shows
tab numbers in Tab mode; its [source and build instructions](./zellij/plugins/tab-mode-indices/README.md)
are included alongside the compiled WASM file.

Before the first rebuild, back up and move the existing `config.kdl` and
`plugins/tab-mode-indices.wasm` out of the way so Home Manager can create its
symlinks. Apply with `sudo darwin-rebuild switch --flake .#work-macbook` from the
repository root, then start a new Zellij session to load the plugin. Zellij asks
for permission to read and change application state on the plugin's first run.

In Normal mode, **Cmd+Alt+Left/Right** switches Zellij tabs in Kitty; use the
left Option key as Alt. **Alt+Left/Right** keeps the combined pane/tab navigation.
**Ctrl+g** toggles Locked mode; return to Normal mode to use the tab shortcuts.
Terminal.app cannot forward Command as Zellij's `Super` modifier.

Highlighting text leaves the selection visible without copying it. **Cmd+C**
copies the Zellij selection in every mode, including Locked mode. Kitty's default
`copy_or_noop` binding copies Kitty selections (such as **Shift+Drag**) and forwards
**Cmd+C** to Zellij when Kitty has no selection.

The tab shortcuts were verified on macOS with Kitty 0.49.2 and Zellij 0.45.1 after
rebuilding, fully quitting and reopening Kitty, and starting a fresh Zellij session. Key-event
captures outside Zellij and inside Locked mode preserved both modifiers as
`CSI 1;11D` (Left) and `CSI 1;11C` (Right). No additional Kitty mappings were needed.

Home Manager reloads changed Zellij settings in existing sessions after
`darwin-rebuild switch`. The `onChange` hook in [home.nix](./home.nix) runs only
when the generated `config.kdl` contents change. Because Nix store files share a
fixed modification time, the hook temporarily replaces the managed symlink with
a fresh copy, waits three seconds for Zellij's file watcher, then restores the
symlink. It also restores the symlink if the hook fails or is interrupted. Panes
and programs keep running; plugin changes can still require a new session.

## Colima

Home Manager manages Colima's [default template](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#setting-the-default-config)
at `~/.colima/_templates/default.yaml`. It keeps the packaged Colima defaults and
sets 8 GiB of memory, the `vz` VM type, and Rosetta support for new profiles.
Colima creates and owns each profile's writable `colima.yaml` on first start;
rebuilds and template changes leave existing profile configurations alone.

Change defaults in [home.nix](./home.nix). Use `colima start --edit` to change an
existing profile. The `colima template` command edits the template managed by
Nix, so make template changes in the flake instead.

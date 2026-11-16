# work-macbook

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

Normal-mode **Cmd+Alt+Left/Right** bindings are configured for switching tabs,
but do not yet work reliably in Kitty. Kitty configuration and shortcut
troubleshooting are pending. **Alt+Left/Right** keeps the combined pane/tab
navigation. Terminal.app cannot forward Command as Zellij's `Super` modifier.

Zellij can miss keybinding changes after a Nix rebuild because the config
symlink's targets have the same fixed modification time. If a session keeps
its old bindings, start a new session; detaching and reattaching preserves the
running session's cached configuration.

## Colima

Home Manager manages Colima's [default template](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#setting-the-default-config)
at `~/.colima/_templates/default.yaml`. It keeps the packaged Colima defaults and
sets 8 GiB of memory, the `vz` VM type, and Rosetta support for new profiles.
Colima creates and owns each profile's writable `colima.yaml` on first start;
rebuilds and template changes leave existing profile configurations alone.

Change defaults in [home.nix](./home.nix). Use `colima start --edit` to change an
existing profile. The `colima template` command edits the template managed by
Nix, so make template changes in the flake instead.

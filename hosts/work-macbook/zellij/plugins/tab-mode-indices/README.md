# Tab mode indices

A background WASM plugin built against the official `zellij-tile = 0.45.1` SDK.
The built-in `zellij:tab-bar` continues to render the tabs. No zjstatus, helper
terminal panes, external commands, timers, or keybinding changes are needed.

`ModeUpdate` detects transitions into and out of Tab mode. `TabUpdate` only
caches tab information; it never triggers a rename. On entry, the plugin saves
each original name and adds its one-based position, for example `[1] editor`.
Repeated Tab mode events do nothing. Tabs opened or moved while in Tab mode
are numbered on the next entry.

On exit to any other mode, the plugin restores saved names by stable tab ID.
It queries current names at mode boundaries, so delayed rename feedback cannot
cause prefix accumulation or hide a later user rename. Cleanup only replaces
names that exactly match the plugin's own saved decoration. Unicode, whitespace,
and existing numbers are preserved; prefixes are never stripped by pattern.
The existing rename-cancel binding (`r`, then Escape) can resurrect a temporary
name from Zellij's undo buffer; returning from RenameTab to Tab also checks that
exact saved name before adding the next prefix. Accepting a rename with Enter
preserves the accepted name, even if it resembles a numbered name.

## Build

With [rustup](https://rustup.rs/) installed, run from this config directory:

```sh
./plugins/tab-mode-indices/build.sh
```

The toolchain file pins Rust 1.91.1 and the `wasm32-wasip1` target. `Cargo.lock`
pins dependencies. The script runs:

```sh
cd plugins/tab-mode-indices
cargo build --locked --release --target wasm32-wasip1
cp target/wasm32-wasip1/release/tab-mode-indices.wasm ../tab-mode-indices.wasm
```

The compiled `../tab-mode-indices.wasm` is included. `config.kdl` loads its
`file:` URL in `load_plugins`; Home Manager replaces `@zellijConfigDir@` with the
user's Zellij config directory and installs the WASM file there. Rebuild the
Darwin configuration after rebuilding the plugin to install the updated file.
The tab-bar alias remains `zellij:tab-bar`. Start a new session to load the plugin.
Zellij prompts once for `ReadApplicationState` and `ChangeApplicationState`.
The SDK groups tab renaming under the latter; it has no narrower rename-only
permission. The plugin requests no other permissions.

## Verification

```sh
cd plugins/tab-mode-indices
cargo test --locked
zellij --config "${XDG_CONFIG_HOME:-$HOME/.config}/zellij/config.kdl" setup --check
```

Native SDK builds used by `cargo test` may need OpenSSL/cURL development libraries
and pkg-config (on Debian/Ubuntu: `pkg-config libssl-dev libcurl4-openssl-dev`).
These are unnecessary for the WASM build.

Validation used the official Zellij 0.45.1 Linux ARM64 binary, downloaded because
no Zellij executable was installed in the sandbox. The eight unit tests cover
all exit modes, repeated events, stale caches, Unicode and pre-numbered names,
stable IDs across moves/closures, genuine renames, and rename cancellation.
An isolated terminal session with separate XDG config/cache/data/runtime paths
also exercised:

- Ctrl+t, then `2`: selects the second tab and restores names in Normal mode.
- Ctrl+t, then Escape or Ctrl+t: restores names.
- Exits to Pane, Locked, Resize, Scroll, Move, Session, Search, EnterSearch,
  RenameTab, RenamePane, Prompt, and Tmux modes: restores names.
- Repeated Tab mode events and rapid entry/exit cycles: no accumulated prefixes.
- Move/close/open tabs while staying in Tab mode: keeps existing prefixes until
  exit, restores the correct surviving names, then renumbers on the next entry.
- A genuine CLI rename while numbered: preserves the new name across exits and
  later entries.
- `r`, then Escape: cancels rename without accumulating prefixes.

## Limits

This targets Zellij 0.45.1's stable-ID and synchronous tab-query APIs; older
versions are unsupported. Validation was in Linux, not the host's macOS terminal.
Use with one attached client: tab names are session-wide, while input modes and
plugin instances belong to clients. Concurrent clients can interfere.

Names really change, so other plugins, CLI queries, and session snapshots can
see the temporary prefixes. Leave Tab mode before unloading/reloading the plugin,
detaching, or stopping the session. There is no shutdown hook to restore names
after a crash, and saved originals exist only in the running plugin's memory.
The SDK also has no atomic compare-and-rename operation: a simultaneous external
rename between the final state query and the restore command can still race.

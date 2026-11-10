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

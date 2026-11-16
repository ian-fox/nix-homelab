mod numbering;

#[cfg(target_family = "wasm")]
use std::collections::BTreeMap;
#[cfg(target_family = "wasm")]
use zellij_tile::prelude::*;

#[cfg(target_family = "wasm")]
#[derive(Default)]
struct State {
    numbering: numbering::Numbering,
}

#[cfg(target_family = "wasm")]
register_plugin!(State);

#[cfg(target_family = "wasm")]
impl ZellijPlugin for State {
    fn load(&mut self, _: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        subscribe(&[EventType::ModeUpdate, EventType::TabUpdate]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::TabUpdate(tabs) => self.numbering.cache_tabs(tabs),
            Event::ModeUpdate(info) => {
                for (id, name) in self.numbering.change_mode(info.mode, get_tab_info) {
                    rename_tab_with_id(id as u64, name);
                }
            }
            _ => {}
        }
        false
    }
}

// Native builds exist only for the state-machine tests.
#[cfg(not(target_family = "wasm"))]
fn main() {}

use std::collections::BTreeMap;
use zellij_tile::prelude::{InputMode, TabInfo};

#[derive(Clone)]
struct NumberedName {
    original: String,
    displayed: String,
}

#[derive(Default)]
pub struct Numbering {
    mode: Option<InputMode>,
    tabs: Vec<TabInfo>,
    names: BTreeMap<usize, NumberedName>,
    rename_cancel: BTreeMap<usize, NumberedName>,
}

impl Numbering {
    pub fn cache_tabs(&mut self, tabs: Vec<TabInfo>) {
        // Our own renames also emit TabUpdate. Never rename in response to one.
        self.tabs = tabs;
    }

    pub fn change_mode(
        &mut self,
        mode: InputMode,
        mut current_tab: impl FnMut(usize) -> Option<TabInfo>,
    ) -> Vec<(usize, String)> {
        let previous_mode = self.mode.replace(mode);
        let was_tab = previous_mode == Some(InputMode::Tab);
        // The existing RenameTab Escape binding undoes the rename, then enters
        // Tab mode. Zellij's undo buffer may contain our temporary name.
        let canceled_names =
            if previous_mode == Some(InputMode::RenameTab) && mode != InputMode::RenameTab {
                let names = std::mem::take(&mut self.rename_cancel);
                if mode == InputMode::Tab {
                    names
                } else {
                    BTreeMap::new()
                }
            } else {
                BTreeMap::new()
            };
        if was_tab == (mode == InputMode::Tab) {
            return vec![];
        }

        if mode == InputMode::Tab {
            // Refresh cached IDs only at the boundary: queued TabUpdates can still
            // contain our previous prefixes, old positions, or a name since edited.
            self.tabs = self
                .tabs
                .iter()
                .filter_map(|tab| current_tab(tab.tab_id))
                .map(|mut tab| {
                    if let Some(name) = canceled_names.get(&tab.tab_id) {
                        if tab.name == name.displayed {
                            tab.name = name.original.clone();
                        }
                    }
                    tab
                })
                .collect();
            self.tabs
                .iter()
                .map(|tab| {
                    let displayed = format!("[{}] {}", tab.position + 1, tab.name);
                    self.names.insert(
                        tab.tab_id,
                        NumberedName {
                            original: tab.name.clone(),
                            displayed: displayed.clone(),
                        },
                    );
                    (tab.tab_id, displayed)
                })
                .collect()
        } else {
            // Query before restoring, even if the rename's TabUpdate hasn't arrived.
            // Stable IDs survive moves; a missing ID means the tab was closed.
            std::mem::take(&mut self.names)
                .into_iter()
                .filter_map(|(id, name)| {
                    let tab = current_tab(id)?;
                    if mode == InputMode::RenameTab && tab.active {
                        self.rename_cancel.insert(id, name.clone());
                    }
                    // A user/application rename owns the name now. Leave it alone.
                    (tab.name == name.displayed).then_some((id, name.original))
                })
                .collect()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct Session {
        numbering: Numbering,
        tabs: BTreeMap<usize, TabInfo>,
    }

    impl Session {
        fn new(names: &[&str]) -> Self {
            let tabs: BTreeMap<_, _> = names
                .iter()
                .enumerate()
                .map(|(position, name)| {
                    let tab_id = position + 40;
                    (
                        tab_id,
                        TabInfo {
                            tab_id,
                            position,
                            name: name.to_string(),
                            ..Default::default()
                        },
                    )
                })
                .collect();
            let mut numbering = Numbering::default();
            numbering.cache_tabs(tabs.values().cloned().collect());
            Self { numbering, tabs }
        }

        fn mode(&mut self, mode: InputMode) -> usize {
            let renames = self
                .numbering
                .change_mode(mode, |id| self.tabs.get(&id).cloned());
            let count = renames.len();
            for (id, name) in renames {
                self.tabs.get_mut(&id).unwrap().name = name;
            }
            count
        }

        fn feedback(&mut self) {
            self.numbering
                .cache_tabs(self.tabs.values().cloned().collect());
        }

        fn names(&self) -> Vec<&str> {
            self.tabs.values().map(|tab| tab.name.as_str()).collect()
        }
    }

    #[test]
    fn preserves_exact_originals_on_every_exit_mode() {
        let originals = ["editor", " shell  ", "日本語 🦀", "[7] already 42", ""];
        for mode in [
            InputMode::Normal,
            InputMode::Locked,
            InputMode::Resize,
            InputMode::Pane,
            InputMode::Scroll,
            InputMode::EnterSearch,
            InputMode::Search,
            InputMode::RenameTab,
            InputMode::RenamePane,
            InputMode::Session,
            InputMode::Move,
            InputMode::Prompt,
            InputMode::Tmux,
        ] {
            let mut session = Session::new(&originals);
            assert_eq!(session.mode(InputMode::Tab), originals.len());
            assert_eq!(
                session.names(),
                [
                    "[1] editor",
                    "[2]  shell  ",
                    "[3] 日本語 🦀",
                    "[4] [7] already 42",
                    "[5] "
                ]
            );
            session.feedback();
            assert_eq!(session.mode(mode), originals.len());
            assert_eq!(session.names(), originals);
        }
    }

    #[test]
    fn repeated_events_and_feedback_do_not_rename() {
        let mut session = Session::new(&["editor", "shell"]);
        assert_eq!(session.mode(InputMode::Normal), 0);
        session.mode(InputMode::Tab);
        session.feedback();
        for _ in 0..20 {
            assert!(session
                .numbering
                .change_mode(InputMode::Tab, |_| panic!("unexpected query"))
                .is_empty());
            session.feedback();
            assert_eq!(session.names(), ["[1] editor", "[2] shell"]);
        }
        session.mode(InputMode::Normal);
        session.feedback();
        assert_eq!(session.mode(InputMode::Normal), 0);
        assert_eq!(session.names(), ["editor", "shell"]);
    }

    #[test]
    fn refreshes_across_rapid_transitions_with_stale_feedback() {
        let mut session = Session::new(&["editor", "shell"]);
        for _ in 0..20 {
            session.mode(InputMode::Tab);
            assert_eq!(session.names(), ["[1] editor", "[2] shell"]);
            session.feedback(); // Cache still has prefixes when we next enter.
            session.mode(InputMode::Normal);
            assert_eq!(session.names(), ["editor", "shell"]);
        }
    }

    #[test]
    fn moves_closures_and_new_tabs_keep_stable_identity() {
        let mut session = Session::new(&["editor", "shell", "close me"]);
        session.mode(InputMode::Tab);
        session.tabs.get_mut(&40).unwrap().position = 1;
        session.tabs.get_mut(&41).unwrap().position = 0;
        session.tabs.remove(&42);
        session.tabs.insert(
            90,
            TabInfo {
                tab_id: 90,
                position: 2,
                name: "new".into(),
                ..Default::default()
            },
        );
        session.feedback();
        assert_eq!(session.mode(InputMode::Tab), 0);
        assert_eq!(session.names(), ["[1] editor", "[2] shell", "new"]);
        assert_eq!(session.mode(InputMode::Pane), 2);
        assert_eq!(session.names(), ["editor", "shell", "new"]);
        session.feedback();
        session.mode(InputMode::Tab);
        assert_eq!(session.names(), ["[2] editor", "[1] shell", "[3] new"]);
    }

    #[test]
    fn preserves_genuine_renames_even_without_their_tab_update() {
        let mut session = Session::new(&["editor", "shell"]);
        session.mode(InputMode::Tab);
        session.feedback();
        session.tabs.get_mut(&40).unwrap().name = "[99] 新しい名前".into();
        assert_eq!(session.mode(InputMode::RenameTab), 1);
        assert_eq!(session.names(), ["[99] 新しい名前", "shell"]);
        session.mode(InputMode::Tab);
        assert_eq!(session.names(), ["[1] [99] 新しい名前", "[2] shell"]);
        session.mode(InputMode::Normal);
        assert_eq!(session.names(), ["[99] 新しい名前", "shell"]);
    }

    #[test]
    fn canceling_rename_recovers_the_exact_name_from_zellij_undo() {
        let mut session = Session::new(&["[7] 日本語 🦀", "shell"]);
        session.tabs.get_mut(&40).unwrap().active = true;
        session.mode(InputMode::Tab);
        // TabNameInput 0 saves the temporary name in Zellij's undo buffer.
        session.tabs.get_mut(&40).unwrap().name.clear();
        session.mode(InputMode::RenameTab);
        session.tabs.get_mut(&40).unwrap().name = "[1] [7] 日本語 🦀".into();
        session.mode(InputMode::Tab);
        assert_eq!(session.names(), ["[1] [7] 日本語 🦀", "[2] shell"]);
        session.mode(InputMode::Normal);
        assert_eq!(session.names(), ["[7] 日本語 🦀", "shell"]);
    }

    #[test]
    fn accepting_a_rename_that_equals_the_old_decoration_preserves_it() {
        let mut session = Session::new(&["shell"]);
        session.tabs.get_mut(&40).unwrap().active = true;
        session.mode(InputMode::Tab);
        session.tabs.get_mut(&40).unwrap().name.clear();
        session.mode(InputMode::RenameTab);
        session.tabs.get_mut(&40).unwrap().name = "[1] shell".into();
        session.mode(InputMode::Normal); // Enter accepts, Escape returns to Tab.
        assert_eq!(session.names(), ["[1] shell"]);
        session.mode(InputMode::Tab);
        assert_eq!(session.names(), ["[1] [1] shell"]);
        session.mode(InputMode::Normal);
        assert_eq!(session.names(), ["[1] shell"]);
    }

    #[test]
    fn refreshes_names_and_positions_before_numbering() {
        let mut session = Session::new(&["old", "shell"]);
        session.tabs.get_mut(&40).unwrap().name = "new 123".into();
        session.tabs.get_mut(&40).unwrap().position = 1;
        session.tabs.remove(&41);
        assert_eq!(session.mode(InputMode::Tab), 1);
        assert_eq!(session.names(), ["[2] new 123"]);
        session.mode(InputMode::Normal);
        assert_eq!(session.names(), ["new 123"]);
    }
}

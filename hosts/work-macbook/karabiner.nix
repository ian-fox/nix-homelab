{ pkgs, ... }:
let
  tabMapping = key: modifiers: {
    type = "basic";
    from = {
      key_code = key;
      modifiers = {
        mandatory = [ "option" ];
        optional = [ "caps_lock" ];
      };
    };
    to = [
      {
        key_code = "tab";
        inherit modifiers;
      }
    ];
    conditions = [
      {
        type = "frontmost_application_if";
        bundle_identifiers = [ "^org\\.mozilla\\.firefox$" ];
      }
    ];
  };
in
{
  # Karabiner watches the directory; a symlink to just karabiner.json breaks reloads.
  home.file.".config/karabiner" = {
    source = pkgs.writeTextDir "karabiner.json" (
      builtins.toJSON {
        profiles = [
          {
            name = "Default";
            selected = true;
            complex_modifications.rules = [
              {
                description = "Firefox: Option+Left/Right switches tabs";
                manipulators = [
                  (tabMapping "left_arrow" [
                    "left_control"
                    "left_shift"
                  ])
                  (tabMapping "right_arrow" [ "left_control" ])
                ];
              }
            ];
          }
        ];
      }
    );

    # A rebuild changes the directory's store path, so restart its file watcher.
    onChange = ''
      karabinerService="gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server"
      if /bin/launchctl print "$karabinerService" >/dev/null 2>&1; then
        /bin/launchctl kickstart -k "$karabinerService"
      fi
    '';
  };
}

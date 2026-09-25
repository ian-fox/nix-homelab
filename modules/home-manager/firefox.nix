{ config, lib, ... }:
{
  options.ifox.firefox.macStyleShortcuts = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether to use Alt as Firefox's main shortcut modifier, matching the
      position of Command on a Mac keyboard.
    '';
  };

  config.programs.firefox = lib.mkMerge [
    { enable = true; }
    (lib.mkIf config.ifox.firefox.macStyleShortcuts {
      profiles.default.settings = {
        # Firefox key codes: Ctrl = 17, Alt = 18, Meta = 224.
        "ui.key.accelKey" = 18;

        # Free Alt from Linux's menu/access-key behavior. Move access keys to
        # the corresponding Ctrl combinations so they do not shadow shortcuts.
        "ui.key.menuAccessKey" = 0;
        "ui.key.menuAccessKeyFocuses" = false;
        "ui.key.chromeAccess" = 2;
        "ui.key.contentAccess" = 3;
      };
    })
  ];
}

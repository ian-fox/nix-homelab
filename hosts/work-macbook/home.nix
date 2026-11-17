{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    username = "ifox";
    stateVersion = "26.05";

    packages = [
      pkgs.ripgrep
      pkgs.fd
      pkgs.colima
      pkgs.nushell
      pkgs.google-cloud-sdk
      pkgs.gh
    ];
  };

  programs.kitty = {
    enable = true;
    # Kitty is installed by Homebrew; let it handle shell integration too.
    package = null;
    shellIntegration.mode = null;

    font = {
      name = "Commit Nerd Font Mono";
      size = 18.0;
    };

    settings = {
      copy_on_select = "no";
      select_by_word_characters = "@-./_~?&=%+#:";
      tab_bar_edge = "top";
      tab_bar_style = "separator";
      tab_powerline_style = "slanted";
      macos_option_as_alt = "left";
    };

    mouseBindings."cmd+left release" = "grabbed,ungrabbed mouse_click_url";
    extraConfig = builtins.readFile ./kitty/current-theme.conf;
  };

  programs.zellij = {
    enable = true;
    extraConfig = lib.replaceStrings [ "@zellijConfigDir@" ] [ "${config.xdg.configHome}/zellij" ] (
      builtins.readFile ./zellij/config.kdl
    );
  };

  xdg.configFile."zellij/config.kdl".onChange = ''
    (
      configFile=${lib.escapeShellArg "${config.xdg.configHome}/zellij/config.kdl"}
      configTarget=$(readlink "$configFile")
      reloadFile=$(mktemp "''${configFile}.reload.XXXXXX")
      trap 'ln -sfn "$configTarget" "$configFile"; rm -f "$reloadFile"' EXIT
      trap 'exit 1' HUP INT TERM

      # Give Zellij's file watcher a fresh timestamp, then restore the Nix symlink.
      cp -L "$configFile" "$reloadFile"
      mv -f "$reloadFile" "$configFile"
      sleep 3
    )
  '';

  xdg.configFile."zellij/plugins/tab-mode-indices.wasm".source =
    ./zellij/plugins/tab-mode-indices.wasm;

  # Colima uses this template to create a writable config for each new profile.
  home.file.".colima/_templates/default.yaml".source =
    pkgs.runCommand "colima-default.yaml"
      {
        nativeBuildInputs = [ pkgs.yq-go ];
      }
      ''
        # Keep upstream defaults for settings not explicitly overridden here.
        yq '.memory = 8 | .vmType = "vz" | .rosetta = true | .mountType = "virtiofs"' \
          ${pkgs.colima.src}/embedded/defaults/colima.yaml > "$out"
      '';
}

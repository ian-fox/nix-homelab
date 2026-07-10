{ ... }:
{
  flake.modules.darwin.ifox = {
    users.users.ifox = {
      home = "/Users/ifox";
    };
  };

  flake.modules.nixos.ifox =
    { config, ... }:
    {
      sops.secrets."ifox-password" = { };
      sops.secrets."ifox-ssh-key" = { };
      users.users.ifox = {
        isNormalUser = true;
        home = "/home/ifox";
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.sops.secrets."ifox-password".path;
        openssh.authorizedKeys.keyFiles = [ config.sops.secrets."ifox-ssh-key".path ];
      };
    };

  flake.modules.homeManager.ifox = {
    home.username = "ifox";
    home.stateVersion = "25.05";
  };
}

{ ... }:
{
  flake.modules.darwin.ifox = {
    users.users.ifox = {
      home = "/Users/ifox";
    };
  };

  flake.modules.homeManager.ifox = {
    home.username = "ifox";
    home.homeDirectory = "/Users/ifox";
    home.stateVersion = "25.05";
  };
}

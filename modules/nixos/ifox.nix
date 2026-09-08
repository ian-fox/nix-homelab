{ inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  users.users.ifox = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsxaPgxP3IFVGWxiEoO3TP16zIdc5YVBrOdbtFNUNeT macbook"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ifox = {
      imports = [ ../home-manager/dev-tools.nix ];

      home = {
        username = "ifox";
        homeDirectory = "/home/ifox";
        stateVersion = "26.05";
      };

      programs.home-manager.enable = true;
    };
  };
}

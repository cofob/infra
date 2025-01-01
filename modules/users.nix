{ config, self, pkgs, lib, ... }:

let
  ssh-keys = import "${self}/ssh-keys.nix";
  cfg = config.custom.users;
in {
  options.custom.users = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable custom users";
    };
    groups.superadmins.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable superadmins group";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      age.secrets.password-root.file = "${pkgs.secrets}/passwords/root.age";

      users = {
        # Users are managed only by NixOS, disable imperative management
        mutableUsers = false;

        users.root.hashedPasswordFile = config.age.secrets.password-root.path;
      };
    }
    (lib.mkIf cfg.groups.superadmins.enable {
      age.secrets.password-cofob.file = "${pkgs.secrets}/passwords/cofob.age";

      users.users = {
        cofob = {
          isNormalUser = true;
          description = "Egor Ternovoi";
          extraGroups = [ "wheel" ];
          uid = 1001;
          hashedPasswordFile = config.age.secrets.password-cofob.path;
          openssh.authorizedKeys.keys = ssh-keys.users.cofob;
          shell = pkgs.bashInteractive;
        };
      };
    })
  ]);
}

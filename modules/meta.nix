# Meta module does not do anything by itself, but it used to store meta information about the server.
{ config, lib, ... }:

{
  options.meta = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable meta module";
    };

    ip = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
      description = "IP address of server";
    };
  };

  config.assertions = lib.mkIf config.meta.enable [{
    assertion = config.meta.ip != null;
    message = "Server IP address is not set";
  }];
}

{ ... }:

{
  imports = [ ./domains ];

  services.btrfs.autoScrub.enable = true;

  nixpkgs.config.allowUnfree = true;
  services.tailscale.enable = true;

  # Not a VM
  custom.common.vm-defaults.enable = false;
  # Use systemd-boot
  custom.common.setup-grub.enable = false;
  custom.common.setup-systemd-boot.enable = true;

  systemd.network = {
    enable = true;

    # Configure network for eno8303
    networks."25-eno8303" = {
      matchConfig = { Name = "eno8303"; };
      networkConfig = {
        Address = "10.0.24.29/21";
        Gateway = "10.0.24.1";
        DNS = "1.1.1.1";
      };
      routes = [{
        Destination = "0.0.0.0/0";
        Gateway = "10.0.24.1";
        Metric = 100;
      }];
    };

    # Bridge for OPNsense
    netdevs."25-br0" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br0";
        MACAddress = "none";
      };
    };

    # Bind the bridge to the eno8403 interface
    networks."25-br0-eno8403" = {
      matchConfig = { Name = "eno8403"; };
      networkConfig = { Bridge = "br0"; };
    };

    # Configure the bridge
    networks."25-br0" = {
      matchConfig = { Name = "br0"; };
      linkConfig = { RequiredForOnline = "routable"; };
      networkConfig = { DHCP = "yes"; };
    };

    # Inherit MAC address from eno8403
    links."25-br0" = {
      matchConfig = { OriginalName = "br0"; };
      linkConfig = { MACAddressPolicy = "none"; };
    };

    # Bridge for VMs
    netdevs."25-br1" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br1";
      };
    };

    # Configure the bridge
    networks."25-br1" = {
      matchConfig = { Name = "br1"; };
      networkConfig = {
        Address = "10.190.0.0/24";
        DNS = "10.190.0.1";
        Gateway = "10.190.0.1";
      };
      # Route remote traffic through the gateway
      routes = [
        # VPN
        {
          Destination = "10.190.0.0/17";
          Gateway = "10.190.0.1";
          Metric = 10;
        }
      ];
    };
  };

  networking = {
    hostName = "odin";
    useNetworkd = true;
    useDHCP = false;
    networkmanager.enable = false;
  };

  meta.ip = "10.190.0.0";
}

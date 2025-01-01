{ pkgs, config, lib, nixpkgs, ... }:

let cfg = config.custom.common;
in {
  options.custom.common = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable common configuration";
    };
    open-ssh-port.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Open SSH port in the firewall";
    };
    default-packages.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Install default packages";
    };
    overwrite-binary-caches.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Overwrite binary caches";
    };
    vm-defaults.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable VM defaults";
    };
    tmp-defaults.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable tmp defaults";
    };
    ssh-defaults.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable SSH defaults";
    };
    pbs-defaults.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable PBS defaults";
    };
    docker-defaults.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable Docker defaults";
    };
    setup-age.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Setup age";
    };
    setup-grub.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable GRUB";
    };
    setup-systemd-boot.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Enable systemd-boot";
    };
    tailscale.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable Tailscale";
    };
    tailscale.open-ssh-port = lib.mkOption {
      default = cfg.open-ssh-port.enable;
      type = lib.types.bool;
      description = "Open SSH port for Tailscale";
    };
    configure-acme.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Configure ACME";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      boot.loader.grub.configurationLimit = 50;

      users.groups.trusted-nix = { };
      users.groups.allowed-nix = { };

      nix = {
        settings = lib.mkMerge [
          {
            auto-optimise-store = true;
            allowed-users = [ "@trusted-nix" "@allowed-nix" "@users" ];
            trusted-users = [ "@trusted-nix" "@wheel" ];
          }
          (lib.mkIf cfg.overwrite-binary-caches.enable {
            substituters = lib.mkForce [
              # cache.nixos.org mirror
              "https://nixos-cache-proxy.cofob.dev"
              # cache.nixos.org
              "https://cache.nixos.org"
            ];
          })
        ];

        extraOptions = ''
          experimental-features = nix-command flakes
          keep-outputs = true
          keep-derivations = true
        '';

        # Enable garbage collection for the Nix store.
        # This will automatically run the garbage collector on a weekly basis.
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };

        # Nix store optimisation.
        # This will automatically optimise the Nix store on a weekly basis.
        optimise = {
          automatic = true;
          dates = [ "weekly" ];
        };

        # Disable nix-channel
        channel.enable = false;
        # Add nixpkgs to the Nix search path.
        nixPath = [ "nixpkgs=${nixpkgs}" ];
        # Use local registry for nixpkgs.
        registry.nixpkgs = lib.mkForce {
          from = {
            type = "indirect";
            id = "nixpkgs";
          };
          to = {
            type = "path";
            path = "${nixpkgs}";
          };
        };
      };

      # Use docker by default for containers.
      virtualisation.oci-containers.backend = "docker";
      virtualisation.docker.autoPrune.enable = true;

      # User-space OOM killer to prevent system freezes.
      services.earlyoom.enable = lib.mkDefault true;

      # Disable password prompt for users in the wheel group.
      security.sudo.wheelNeedsPassword = lib.mkDefault false;

      # Set locale and timezone.
      time.timeZone = lib.mkDefault "Europe/Moscow";
      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

      # Enable the OpenSSH daemon.
      services.openssh.enable = lib.mkDefault true;

      # System initialized at 24.05.
      # DO NOT CHANGE THIS VALUE!
      system.stateVersion =
        lib.mkDefault "24.05"; # DID YOU READ THE COMMENT ABOVE?

      # Enable the NetworkManager service.
      networking.networkmanager.enable = lib.mkDefault true;

      # Enable DHCP for networking.
      networking.useDHCP = lib.mkDefault true;

      # # Disable resolvconf and NetworkManager DNS.
      # networking.networkmanager.dns = "none";
      # networking.resolvconf.enable = false;
      # # Use DNS directly.
      # networking.nameservers = [ "10.190.0.1" ];
      # networking.search = [ "lo.madloba.org" ];
      # # Overwrite /etc/resolv.conf with custom nameserver on every boot.
      # systemd.services.updateResolvConf = let
      #   resolv-conf = builtins.toFile "resolv.conf" ''
      #     # Generated by NixOS
      #     ${lib.concatStringsSep "\n"
      #     (map (nameserver: "nameserver ${nameserver}")
      #       config.networking.nameservers)}
      #     search ${lib.concatStringsSep " " config.networking.search}
      #   '';
      # in {
      #   description = "Update /etc/resolv.conf with custom nameserver";
      #   wantedBy = [ "network-pre.target" "multi-user.target" ];
      #   before = [ "network.target" ];

      #   script = ''
      #     echo "Updating /etc/resolv.conf with custom nameserver"
      #     if [ -f /etc/resolv.conf ]; then
      #       echo "Making /etc/resolv.conf mutable"
      #       chattr -i /etc/resolv.conf
      #       echo "Removing /etc/resolv.conf"
      #       rm -f /etc/resolv.conf
      #     fi
      #     echo "Writing /etc/resolv.conf"
      #     cp -f ${resolv-conf} /etc/resolv.conf
      #     echo "Making /etc/resolv.conf immutable"
      #     chattr +i /etc/resolv.conf
      #   '';

      #   serviceConfig.Type = "oneshot";
      # };

      # # Set NTP server.
      # networking.timeServers = lib.mkForce [ "ntp.madloba.org" ];

      # By-default use x86_64-linux platform.
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # Enable MTR (My Traceroute) program.
      programs.mtr.enable = lib.mkDefault true;
    }
    (lib.mkIf cfg.vm-defaults.enable {
      # Enable VirIO drivers for QEMU guests.
      boot.initrd.availableKernelModules = [
        "virtio_net"
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        "virtio_scsi"
        "9p"
        "9pnet_virtio"
        "uhci_hcd"
        "ehci_pci"
        "ahci"
        "sr_mod"
      ];
      boot.initrd.kernelModules =
        [ "virtio_balloon" "virtio_console" "virtio_rng" "virtio_gpu" ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      # Enable Guest Agent
      # This allows the host to communicate with the guest and perform various
      # operations, such as shutting down the guest.
      services.qemuGuest.enable = true;
    })
    (lib.mkIf (cfg.setup-age.enable && cfg.configure-acme.enable) {
      # Accept CA ToS
      age.secrets.credentials-cloudflare-api-token.file =
        "${pkgs.secrets}/credentials/cloudflare/api-token.age";

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "cofob@riseup.net";
          dnsResolver = "1.1.1.1:53";
          dnsProvider = "cloudflare";
          credentialsFile =
            config.age.secrets.credentials-cloudflare-api-token.path;
          extraLegoFlags = [ "--dns" "cloudflare" ];
        };
      };
    })
    (lib.mkIf cfg.default-packages.enable {
      # Add default packages to the system.
      environment.systemPackages = with pkgs; [
        jq
        nano
        vim
        wget
        curl
        htop
        nload
        ncdu
        sudo
        dig
        rsync
        ffsend
        tcpdump
      ];
    })
    (lib.mkIf cfg.open-ssh-port.enable {
      # Open ports for SSH in the firewall.
      networking.firewall.allowedTCPPorts = [ 22 ];
    })
    (lib.mkIf cfg.tmp-defaults.enable {
      # Use tmpfs for /tmp and clean it on boot.
      # This limits the size of /tmp to half of the available RAM, but reduces
      # the number of writes to the disk and speeds up the system.
      boot.tmp = {
        useTmpfs = true;
        cleanOnBoot = true;
      };
    })
    (lib.mkIf cfg.setup-age.enable {
      # Setup age.
      age.identityPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
    })
    (lib.mkIf cfg.setup-grub.enable {
      # Use the GRUB 2 boot loader.
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/vda";
    })
    (lib.mkIf cfg.setup-systemd-boot.enable {
      # Use the systemd-boot EFI boot loader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })
    (lib.mkIf cfg.ssh-defaults.enable {
      # Set up SSH defaults.
      services.openssh = {
        authorizedKeysInHomedir = false;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };
    })
    (lib.mkIf cfg.pbs-defaults.enable {
      # Set up Proxmox Backup Server defaults.
      age.secrets.credentials-proxmox-backup-key.file =
        "${pkgs.secrets}/credentials/proxmox-backup/key.age";
      age.secrets.credentials-proxmox-backup-env.file =
        "${pkgs.secrets}/credentials/proxmox-backup/env.age";
      custom.proxmox-backup = {
        enable = true;
        fingerprint =
          "88:c0:0e:76:3a:4a:23:95:38:e0:d2:65:d5:37:73:86:dc:94:fa:c3:46:84:c8:e8:0b:85:8d:03:63:f0:fe:87";
        namespace = "madloba";
        keyFile = config.age.secrets.credentials-proxmox-backup-key.path;
        envFile = config.age.secrets.credentials-proxmox-backup-env.path;
      };
    })
    (lib.mkIf cfg.docker-defaults.enable {
      # Set up Docker defaults.
      virtualisation.docker.daemon.settings.default-address-pools = [{
        base = "10.200.0.0/16";
        size = 24;
      }];
    })
    (lib.mkIf (cfg.docker-defaults.enable && cfg.pbs-defaults.enable
      && config.virtualisation.docker.enable) {
        # Backup Docker volumes.
        custom.proxmox-backup.jobs.daily.paths = [{
          name = "docker-volumes";
          path = "/var/lib/docker/volumes";
        }];
      })
    (lib.mkIf (config.nix.channel.enable == false) {
      # Remove channels from the system to remove warnings.
      systemd.services.remove-nix-channels = {
        description = "Remove Nix channels";
        wantedBy = [ "multi-user.target" ];

        script = ''
          echo "Removing Nix channels"
          rm -rf /root/.nix-defexpr/channels /nix/var/nix/profiles/per-user/root/channels
        '';

        serviceConfig.Type = "oneshot";
      };
    })
    (lib.mkIf cfg.tailscale.enable {
      # Enable Tailscale.
      age.secrets.credentials-tailscale-authkey.file =
        "${pkgs.secrets}/credentials/tailscale/authkey.age";
      services.tailscale = {
        enable = true;
        authKeyFile = config.age.secrets.credentials-tailscale-authkey.path;
        extraUpFlags = [ "--accept-dns=false" ];
      };
    })
    (lib.mkIf (cfg.tailscale.enable && cfg.tailscale.open-ssh-port) {
      # Open ports for Tailscale in the firewall.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    })
  ]);
}

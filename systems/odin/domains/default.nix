{ self, pkgs, config, ... }:

{
  # Enable nixvirt
  virtualisation.libvirt.enable = true;

  virtualisation.libvirtd.qemu.runAsRoot = false;
  # Allow management of libvirtd over SSH
  virtualisation.libvirtd.extraConfig = ''
    unix_sock_rw_perms = "0770";
    unix_sock_group = "libvirtd"
  '';
  users.users.cofob.extraGroups = [ "libvirtd" ];

  age.secrets."ssh-keys/empty/key" = {
    file = "${pkgs.secrets}/ssh-keys/empty.age";
    mode = "0440";
  };

  systemd.services.vm-ssh-keys = {
    description = "Copy SSH keys for VMs";
    wantedBy = [ "nixvirt.service" ];
    restartTriggers = [ pkgs.secrets ];
    script = ''
      cp -r /run/agenix/ssh-keys/* /var/lib/vm-ssh-keys
      chown -R qemu-libvirtd:qemu-libvirtd /var/lib/vm-ssh-keys/*
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "vm-ssh-keys";
    };
  };

  systemd.services.generate-empty-disk = {
    description = "Generate an empty disk image";
    before = [ "libvirtd.service" "nixvirt.service" ];
    requiredBy = [ "nixvirt.service" ];
    path = [ pkgs.coreutils pkgs.qemu-utils pkgs.e2fsprogs ];
    environment = {
      size = "10G";
      name = "/data/vm/disks/empty.qcow2";
      chown = "qemu-libvirtd:qemu-libvirtd";
      mode = "0600";
    };
    script = ''
      # If the file already exists, do nothing
      if [ -e "$name" ]; then
        exit 0
      fi

      echo "Generating empty disk image $name"
      temp=$(mktemp)
      qemu-img create -f raw "$temp" "$size"
      mkfs.ext4 -L nixos "$temp"
      qemu-img convert -f raw -O qcow2 "$temp" "$name"
      rm "$temp"
      chown "$chown" "$name"
      chmod "$mode" "$name"
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.services.update-empty-domain = let
    s = ''
      virsh -c qemu:///system qemu-agent-command empty '{"execute": "guest-exec", "arguments": { "path": "${self.nixosConfigurations.empty.config.system.build.toplevel}/activate", "arg": [ ], "capture-output": true }}' || true
    '';
  in {
    description = "Update the empty domain";
    after = [ "libvirtd.service" ];
    wants = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.libvirt ];
    restartTriggers =
      [ self.nixosConfigurations.empty.config.system.build.toplevel ];
    script = s;
    serviceConfig = {
      Type = "oneshot";
    };
  };

  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
        definition = let
          systemConfig = self.nixosConfigurations.empty.config;
          toplevel = builtins.trace
            "Activate empty with ${systemConfig.system.build.toplevel}/activate"
            systemConfig.system.build.toplevel;
          regInfo = pkgs.closureInfo { rootPaths = [ toplevel ]; };
          initrd =
            "${systemConfig.system.build.initialRamdisk}/${systemConfig.system.boot.loader.initrdFile}";
        in pkgs.writeTextFile {
          name = "empty.xml";
          text = ''
            <domain type="kvm">
              <name>empty</name>
              <uuid>cf5f8c92-048b-4e58-91ad-c2309bc30c87</uuid>
              <metadata>
                <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
                  <libosinfo:os id="http://libosinfo.org/linux/2022"/>
                </libosinfo:libosinfo>
              </metadata>

              <memory unit="KiB">4194304</memory>
              <currentMemory unit="KiB">4194304</currentMemory>
              <memoryBacking>
                <source type='memfd'/>
                <access mode='shared'/>
              </memoryBacking>

              <vcpu placement="static">2</vcpu>

              <os>
                <type arch="x86_64" machine="pc-q35-9.1">hvm</type>
                <boot dev="hd"/>
                <kernel>${toplevel}/kernel</kernel>
                <initrd>${initrd}</initrd>
                <cmdline>${
                  builtins.readFile "${toplevel}/kernel-params"
                } init=${toplevel}/init regInfo=${regInfo}/registration console=ttyS0,115200n8 console=tty0</cmdline>
              </os>

              <features>
                <acpi/>
                <apic/>
                <vmport state="off"/>
              </features>

              <cpu mode="host-passthrough" check="none" migratable="on"/>
              <clock offset="utc">
                <timer name="rtc" tickpolicy="catchup"/>
                <timer name="pit" tickpolicy="delay"/>
                <timer name="hpet" present="no"/>
              </clock>
              <on_poweroff>destroy</on_poweroff>
              <on_reboot>restart</on_reboot>
              <on_crash>destroy</on_crash>
              <pm>
                <suspend-to-mem enabled="no"/>
                <suspend-to-disk enabled="no"/>
              </pm>

              <devices>
                <emulator>${pkgs.qemu_kvm}/bin/qemu-system-x86_64</emulator>
                <disk type="file" device="disk">
                  <driver name="qemu" type="qcow2"/>
                  <source file="/data/vm/disks/empty.qcow2"/>
                  <target dev="vda" bus="virtio"/>
                </disk>
                <filesystem type='mount' accessmode='passthrough'>
                  <source dir="${builtins.storeDir}"/>
                  <target dir="nix-store"/>
                  <readonly/>
                </filesystem>
                <filesystem type='mount' accessmode='passthrough'>
                  <source dir="/var/lib/vm-ssh-keys/empty"/>
                  <target dir="age"/>
                  <readonly/>
                </filesystem>

                <interface type="bridge">
                  <mac address="52:54:00:cf:5f:8c"/>
                  <source bridge="br1"/>
                  <model type="virtio"/>
                  <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
                </interface>

                <serial type="pty">
                  <target type="isa-serial" port="0">
                    <model name="isa-serial"/>
                  </target>
                </serial>
                <console type="pty">
                  <target type="serial" port="0"/>
                </console>

                <channel type="unix">
                  <target type="virtio" name="org.qemu.guest_agent.0"/>
                  <address type="virtio-serial" controller="0" bus="0" port="1"/>
                </channel>
                <channel type="spicevmc">
                  <target type="virtio" name="com.redhat.spice.0"/>
                  <address type="virtio-serial" controller="0" bus="0" port="2"/>
                </channel>
                <redirdev bus="usb" type="spicevmc">
                  <address type="usb" bus="0" port="2"/>
                </redirdev>
                <redirdev bus="usb" type="spicevmc">
                  <address type="usb" bus="0" port="3"/>
                </redirdev>

                <input type="mouse" bus="ps2"/>
                <input type="keyboard" bus="ps2"/>

                <graphics type="spice" autoport="yes">
                  <listen type="address"/>
                </graphics>
                <video>
                  <model type="virtio" heads="1" primary="yes"/>
                  <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
                </video>

                <memballoon model="virtio">
                  <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
                </memballoon>
                <rng model="virtio">
                  <backend model="random">/dev/urandom</backend>
                  <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
                </rng>
              </devices>
            </domain>'';
        };
        active = true;
        restart = false;
      }
      {
        definition = ./opnsense.xml;
        active = true;
      }
      {
        definition = ./services.xml;
        active = true;
      }
      {
        definition = ./monitoring.xml;
        active = true;
      }
    ];
  };
}

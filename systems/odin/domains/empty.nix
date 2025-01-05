{ pkgs, libvirtConfig, config }:

let vm = pkgs.declarativeVm.generateVm libvirtConfig.name config;
in pkgs.writeTextFile {
  name = "${libvirtConfig.name}.xml";
  text = ''
    <domain type="kvm">
      <name>${libvirtConfig.name}</name>
      <uuid>${libvirtConfig.uuid}</uuid>

      <metadata>
        <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
          <libosinfo:os id="http://libosinfo.org/linux/2022"/>
        </libosinfo:libosinfo>
      </metadata>

      <memory unit="KiB">4194304</memory>
      <currentMemory unit="KiB">4194304</currentMemory>

      <vcpu placement="static">2</vcpu>
      <cpu mode="host-passthrough" check="none" migratable="on"/>

      <os>
        <type arch="x86_64" machine="pc-q35-9.1">hvm</type>
        <boot dev="hd"/>
        ${vm.osBoot}
      </os>

      <features>
        <acpi/>
        <apic/>
        <vmport state="off"/>
      </features>

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
          <source file="/data/vm/disks/${libvirtConfig.name}.qcow2"/>
          <target dev="vda" bus="virtio"/>
        </disk>

        ${vm.filesystems}

        <interface type="bridge">
          <mac address="${libvirtConfig.mac}"/>
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
}

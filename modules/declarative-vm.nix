{ ... }:

{
  nixpkgs.overlays = [
    (prev: final: {
      declarativeVm = {
        # Helper function to generate a VM configuration for libvirt.
        generateVm = name: system: rec {
          # Get the system configuration.
          systemConfig = system.config;
          # Derivation with the system configuration.
          toplevel = builtins.trace
            "Activate ${name} with ${systemConfig.system.build.toplevel}/bin/switch-to-configuration switch"
            systemConfig.system.build.toplevel;
          # Info for nix garbage collector.
          regInfo = final.closureInfo { rootPaths = [ toplevel ]; };
          regInfoRegistration = "${regInfo}/registration";
          # Boot configuration.
          initrd =
            "${systemConfig.system.build.initialRamdisk}/${systemConfig.system.boot.loader.initrdFile}";
          kernel = "${toplevel}/kernel";
          kernelParams = builtins.readFile "${toplevel}/kernel-params";
          consoleParams = "console=ttyS0,115200n8 console=tty0";
          init = "${toplevel}/init";
          cmdline = ''
            ${kernelParams} init=${init} regInfo=${regInfoRegistration} ${consoleParams}
          '';
          # Template for the os section in the libvirt domain XML.
          osBoot = ''
            <kernel>${kernel}</kernel>
            <initrd>${initrd}</initrd>
            <cmdline>${cmdline}</cmdline>
          '';
          # Shared nix store and age filesystems.
          storeFilesystem = ''
            <filesystem type='mount' accessmode='passthrough'>
              <source dir="${builtins.storeDir}"/>
              <target dir="nix-store"/>
              <readonly/>
            </filesystem>
          '';
          ageFilesystem = ''
            <filesystem type='mount' accessmode='passthrough'>
              <source dir="/var/lib/vm-ssh-keys/${name}"/>
              <target dir="age"/>
              <readonly/>
            </filesystem>
          '';
          filesystems = ''
            ${storeFilesystem}
            ${ageFilesystem}
          '';
        };
      };
    })
  ];
}

{ self, lib, ... }:

{
  nixpkgs.overlays = [
    (prev: final: {
      crossSystem = rec {
        # Get all system configuration names.
        systemNames = lib.attrNames self.nixosConfigurations;
        # Get system configuration by name.
        getSystem = name: self.nixosConfigurations."${name}".config;
        # Add lo.madloba.org domain name to hostname.
        addDomain = hostname: "${hostname}.lo.madloba.org";
        # Same as addDomain, but for a list of hostnames.
        addDomains = hostnames: map (hostname: addDomain hostname) hostnames;
        # Attribute set of all systems. The attribute name is the system name.
        allSystems = builtins.listToAttrs (map (name: {
          name = name;
          value = getSystem name;
        }) systemNames);
        # Attribute set of IPs of all systems. The attribute name is the system name.
        systemIPs = builtins.listToAttrs (map (name: {
          name = name;
          value = allSystems."${name}".meta.ip;
        }) systemNames);
        # Filter out systems names that don't match a predicate.
        filterSystemNames = p:
          builtins.filter (name: (p name (getSystem name))) systemNames;
        # Same as filterSystemNames, but adds domain name to hostnames.
        filterSystemNamesWithDomain = p: addDomains (filterSystemNames p);
      };
    })
  ];
}

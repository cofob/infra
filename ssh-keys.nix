# All public SSH keys are stored here
let
  # Function to merge all lists from a attribute set into a single list
  squash = attrs: builtins.concatLists (builtins.attrValues attrs);
in rec {
  users = {
    cofob = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsSKOtKRM9+bvCs6iioOrcayMdsdwaQN/lJAQJkXE+w cofob@yubi"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFg9JjdQH3neby5z1IWB8xlMzWtfnaWvTJX82+p+Qapp cofob@twinkpad2"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExfGCQE5rcchNNv7IVc5mIn1A6QGZ/eLrDIW0mJaXTm cofob@mac"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzB+g6qthKy95lG3UxnikrHCaVZ9O9njEqzdCIIfXxL cofob@twinkpad"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwLbr2pWwVTio+ta0o3miV8BkxlRM8ulwUWboPgPT0T cofob@pixel-termius"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETMEzhigdZelWae3V4tQ7/LXsub39SRG2X+jPMeoHMx cofob@deprecated-key"
    ];
  };

  systems = {
    odin = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFQWIjYX92rTyERnPmyUBvSOjWS/p4neMo6wRSwh5dy"
    ];

    monitoring = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQ6LAiM+numnlihD0qLoPHmk3FSc5xwiyZqonXq9WFv"
    ];
  };

  roles = { monitoring = systems.monitoring; };

  other = { };

  all-users = squash users;
  all-systems = squash systems;
  all = all-users ++ all-systems;
}

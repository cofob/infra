{ ... }:

{
  custom.common.declarative-vm.enable = true;

  # Ephemerally connect to Tailscale.
  custom.common.tailscale.ephemeral = true;

  networking.hostName = "empty";
}

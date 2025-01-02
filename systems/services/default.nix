{ ... }:

{
  roles.utility.cf-ts-dnssync.enable = true;
  roles.utility.cf-opn-dnssync.enable = true;

  meta.ip = "10.190.0.4";
  networking.hostName = "services";
}

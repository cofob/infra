{ ... }:

{
  roles.utility.cf-ts-dnssync.enable = true;
  roles.utility.cf-opn-dnssync.enable = true;
  roles.media.navidrome.enable = true;

  networking.hostName = "services";
}

{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/16bb5d77-d29f-4a36-bdc2-686ae973a6bb";
    fsType = "ext4";
  };

  fileSystems."/mnt/music" = {
    device = "/dev/disk/by-uuid/08c6d25b-af4e-4fe5-b970-395511e57af5";
    fsType = "ext4";
  };

  fileSystems."/mnt/movies" = {
    device = "/dev/disk/by-uuid/c548b231-00cb-454d-bda1-d63c062ae4f0";
    fsType = "ext4";
  };

  swapDevices = [ ];
}

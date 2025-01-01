pkgs:

{
  secrets = pkgs.callPackage ./secrets.nix { };
  nginx-custom = pkgs.callPackage ./nginx-custom { };
  default-ssl-cert = pkgs.callPackage ./default-ssl-cert.nix { };
}

{ stdenv, openssl }:

stdenv.mkDerivation {
  pname = "default-ssl-cert";
  version = "1";

  buildInputs = [ openssl ];

  buildPhase = ''
    openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes \
      -subj "/C=DF/ST=DefaultSSL/L=DefaultSSL/O=DefaultSSL/OU=DefaultSSL/CN=DefaultSSL"
  '';

  installPhase = ''
    mkdir -p $out
    cp cert.pem $out/cert.pem
    cp key.pem $out/key.pem
  '';

  phases = [ "buildPhase" "installPhase" ];

  meta = {
    description = "Default SSL certificate";
    longDescription = ''
      This package provides a default SSL certificate for use as a stub in SSL connections.

      IT IS NOT SECURE AND SHOULD NOT BE USED TO SECURE ANYTHING.
    '';
  };
}

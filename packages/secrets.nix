{ stdenv, ... }:

stdenv.mkDerivation {
  name = "secrets";
  src = ../secrets;
  installPhase = ''
    mkdir -p $out
    # Copy only files ending with .age to $out
    find . -type f -name '*.age' -exec cp --parents {} $out \;
  '';
  meta = {
    description =
      "A package containing secrets. It is used to remove self dependency from configurations and prevent source code leaks.";
  };
}

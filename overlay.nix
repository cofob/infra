pkgs: inputs:
{ } // (import ./packages/top-level.nix {
  inherit inputs;
  callPackage = pkgs.callPackage;
})

{ self, nixpkgs-unstable, ... }:

{
  nixpkgs.overlays = [
    self.overlays.default
    (prev: final: {
      unstable = import nixpkgs-unstable { system = final.system; };
    })
  ];
}

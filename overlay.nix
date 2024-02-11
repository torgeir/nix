final: prev:

let inherit (prev) lib callPackage;
in {
  # remember to add these files to git for nix to discover them
  neural-amp-modeler-lv2 = callPackage ./pkgs/neural-amp-modeler-lv2 { };
}

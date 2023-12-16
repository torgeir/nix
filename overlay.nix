self: super:

let
  inherit (super) lib callPackage;
  a = 1;
in {
  # remember to add these files to git for nix to discover them
  neural-amp-modeler-lv2 = callPackage ./pkgs/neural-amp-modeler-lv2 { };

}

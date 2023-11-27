self: super:

let
  inherit (super) lib callPackage;
  a = 1;
in { rtirq = callPackage ./pkgs/rtirq { }; }

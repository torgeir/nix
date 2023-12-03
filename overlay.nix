self: super:

let
  inherit (super) lib callPackage;
  a = 1;
in {
  # TODO this is not used any longer, just serves as an example
  rtirq = callPackage ./pkgs/rtirq { };
}

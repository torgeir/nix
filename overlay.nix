final: prev:

let inherit (prev) lib callPackage;
in {
  # remember to add these files to git for nix to discover them
  neural-amp-modeler-lv2 = callPackage ./pkgs/neural-amp-modeler-lv2 { };

  # https://github.com/quickemu-project/quickemu/issues/722
  qemu = prev.qemu.override { smbdSupport = true; };
}

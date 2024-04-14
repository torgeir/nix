{ inputs }:
final: prev:

let inherit (prev) lib callPackage;
in {
  # remember to add these files to git for nix to discover them
  neural-amp-modeler-lv2 = callPackage ./pkgs/neural-amp-modeler-lv2 { };

  # https://github.com/quickemu-project/quickemu/issues/722
  qemu = prev.qemu.override { smbdSupport = true; };

  # pkgs.unstable.<something>
  unstable = import inputs.nixpkgs-unstable { system = prev.system; };

  # pkgs.unstable-locked.<something>
  unstable-locked = import inputs.nixpkgs-locked { system = prev.system; };
}

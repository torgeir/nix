{ inputs }:
final: prev:

let inherit (prev) lib callPackage;
in {
  # remember to add these files to git for nix to discover them
  neural-amp-modeler-lv2 = callPackage ./pkgs/neural-amp-modeler-lv2 { };

  # opentrack with neural-net tracker support
  opentrack = prev.opentrack.overrideAttrs (old: rec {
    # version = "2023.3.0";
    version = "2024.1.1";
    src = final.fetchFromGitHub {
      owner = "opentrack";
      repo = "opentrack";
      rev = "opentrack-${version}";
      hash = "sha256-C0jLS55DcLJh/e5yM8kLG7fhhKvBNllv5HkfCWRIfc4=";
    };
    nativeBuildInputs = old.nativeBuildInputs
      ++ (with final; [ wine64Packages.base pkgsi686Linux.glibc onnxruntime ]);
    cmakeFlags = old.cmakeFlags ++ [
      "-DSDK_WINE=ON"
      "-DONNXRuntime_INCLUDE_DIR=${final.onnxruntime.dev}/include"
    ];
  });

  # https://github.com/quickemu-project/quickemu/issues/722
  qemu = prev.qemu.override { smbdSupport = true; };

  # pkgs.stable.<something>
  stable = import inputs.nixpkgs-stable {
    system = prev.system;
    config.allowUnfree = true; # "linuxsampler"
  };

  # unstable is default now
  # pkgs.unstable.<something>
  #unstable = import inputs.nixpkgs-unstable { system = prev.system; };

  # pkgs.unstable-locked.<something>
  unstable-locked = import inputs.nixpkgs-locked { system = prev.system; };
}

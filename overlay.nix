{ inputs }:
final: prev:

let inherit (prev) lib callPackage;
in {

  # opentrack with neural-net tracker support
  opentrack = prev.opentrack.overrideAttrs (old: rec {
    # version = "2023.3.0";
    version = "2024.1.1";
    src = final.fetchFromGitHub {
      owner = "opentrack";
      repo = "opentrack";
      rev = "766808196cf63ddf9ceb102fba193582daceb9de";
      hash = "sha256-xS87LFAbnRg7uBbN7ARoGts3bNYkcpOm3xhojBepgIo=";
    };
    nativeBuildInputs = old.nativeBuildInputs
      ++ (with final; [ wine64Packages.base pkgsi686Linux.glibc onnxruntime ]);
    buildInputs = old.buildInputs ++ (with final; [ qt6.qtbase qt6.qttools ]);
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

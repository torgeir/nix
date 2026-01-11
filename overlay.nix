{ inputs }:
final: prev:

let
  inherit (prev) lib callPackage;
in
{

  kotlin-lsp-official = prev.callPackage (inputs.nix-home-manager + "/pkgs/kotlin-lsp.nix") { };

  # latest version known to work with DCS
  # https://github.com/ValveSoftware/Proton/issues/1722#issuecomment-3563401892
  proton-ge-bin =
    let
      v = "GE-Proton10-26";
    in
    prev.lib.overrideDerivation prev.proton-ge-bin (old: {
      name = "proton-ge-bin";
      version = v;
      src = final.fetchzip {
        url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${v}/${v}.tar.gz";
        hash = "sha256-Q5bKTDn3sTgp4mbsevOdN3kcdRsyKylghXqM2I2cYq8=";
      };
      # fix reference to finalAttrs.version in preFix in proton-ge-bin derivation
      preFixup = ''
        substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
        --replace-fail "${v}" "${v}"
      '';
    });

  # yabridge = prev.yabridge.overrideAttrs (old: rec {
  #   src = prev.fetchFromGitHub {
  #     owner = "robbert-vdh";
  #     repo = "yabridge";
  #     rev = "refs/heads/new-wine10-embedding";
  #     hash = "sha256-FaFFoVNJeh/y/3MGZ+pWZrHI+du44GExhZRNZBuUtio=";
  #   };
  #   patches = prev.lib.drop 1 old.patches;
  # });

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
    nativeBuildInputs =
      old.nativeBuildInputs
      ++ (with final; [
        wine64Packages.base
        pkgsi686Linux.glibc
        onnxruntime
      ]);
    buildInputs =
      old.buildInputs
      ++ (with final; [
        qt6.qtbase
        qt6.qttools
      ]);
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

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

  # lock to wine 9.21 for yabridge to play nice with helix native
  # TODO not working yet
  # claude 2
  #wine-tkg = let
  #  # Your wine-tkg source
  #  tkg-src = prev.fetchFromGitHub {
  #    owner = "Kron4ek";
  #    repo = "wine-tkg";
  #    rev = "9.21";
  #    hash = "sha256-p5J09a9RUnpzcudDkHnI0LNKskXxwReaBxTp73utvko=";
  #  };

  #  # Create custom wine packages with wine-tkg source
  #  wineTkgPackages = prev.callPackage "${prev.path}/pkgs/applications/emulators/wine" {
  #    wineRelease = "unstable";
  #    wineBuild = "wineWow";
  #  };
  #in
  #wineTkgPackages.full.overrideAttrs (oldAttrs: {
  #  pname = "wine-tkg";
  #  version = "9.21";
  #  src = tkg-src;
  #  patches = []; # wine-tkg usually includes its own patches
  #});

  # staging with tkg patches manually added

  # wine-tkg = prev.wineWowPackages.yabridge.overrideAttrs (old: {
  #   patches = let
  #     tkg = prev.fetchFromGitHub {
  #       owner = "Frogging-Family";
  #       repo = "wine-tkg-git";
  #       rev = "7db90c1dc0831ca2ecad31c1ebf4b32992a1c79e";
  #       hash = "sha256-LQ4UlL2M9tNo6Fa8SDi3QMOhISEyg9sO2/otOeJyE8I=";
  #     };
  #     tkg-patch-dir = "${tkg}/wine-tkg-git/wine-tkg-patches";
  #   in
  #     (old.patches or []) ++ [
  #       # staging patches
  #       "${tkg-patch-dir}/proton/fsync/fsync-staging-no_alloc_handle.patch"
  #       "${tkg-patch-dir}/proton/fsync/fsync_futex_waitv.patch"
  #       "${tkg-patch-dir}/proton/fsync/fsync-unix-staging.patch"
  #       # "${tkg-patch-dir}/proton/fsync/fsync-spincounts.patch"
  #     ];
  # });

  #
#wine-tkg = prev.wineWowPackages.yabridge.overrideAttrs (oldAttrs:
#let
#  version = "9.21";
#in rec {
#  inherit version;
#
#  src = prev.fetchurl {
#    url = "https://dl.winehq.org/wine/source/9.x/wine-${version}.tar.xz";
#    hash = "sha256-REK0f/2bLqRXEA427V/U5vTYKdnbeaJeYFF1qYjKL/8=";
#  };
#
#  # Use wine-tkg staging patches instead of wine-staging
#  staging = prev.fetchFromGitHub {
#    owner = "Kron4ek";
#    repo = "wine-tkg";
#    rev = "9.21";
#    # hash = "sha256-nhn5oRHHB3bue4WY6/gMYxMXv7iJxJiJxkOKCbp4lhY=";
#    hash = "sha256-p5J09a9RUnpzcudDkHnI0LNKskXxwReaBxTp73utvko=";
#  };
#
#  # Keep the same gecko and mono versions as yabridge
#  gecko32 = prev.fetchurl rec {
#    version = "2.47.4";
#    url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86.msi";
#    hash = "sha256-Js7MR3BrCRkI9/gUvdsHTGG+uAYzGOnvxaf3iYV3k9Y=";
#  };
#
#  gecko64 = prev.fetchurl rec {
#    version = "2.47.4";
#    url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86_64.msi";
#    hash = "sha256-5ZC32YijLWqkzx2Ko6o9M3Zv3Uz0yJwtzCCV7LKNBm8=";
#  };
#
#  mono = prev.fetchurl rec {
#    version = "9.3.0";
#    url = "https://dl.winehq.org/wine/wine-mono/${version}/wine-mono-${version}-x86.msi";
#    hash = "sha256-bKLArtCW/57CD69et2xrfX3oLZqIdax92fB5O/nD/TA=";
#  };
#
#  # TODO torgeir prøv det
#  # You can modify patches if needed, or keep yabridge's patches
#  # patches = oldAttrs.patches ++ [ /* additional patches */ ];
#});

  # TODO
#  wine-tkg = inputs.nix-gaming.packages.${prev.system}.wine-tkg.overrideAttrs(old: {
#    version = "9.21";
#    src = prev.fetchurl {
#      url = "https://github.com/Kron4ek/wine-tkg/archive/refs/tags/9.21.tar.gz";
#      sha256 = "sha256-nhn5oRHHB3bue4WY6/gMYxMXv7iJxJiJxkOKCbp4lhY=";
#    };
#
#    patches = (old.patches or [])++ [
#      (prev.writeText "fix-staging-wchar.patch" ''
#--- a/programs/winecfg/staging.c
#+++ b/programs/winecfg/staging.c
#@@ -50,7 +50,7 @@ static void csmt_set(BOOL status)
#     else
#     {
#         // FALSE, we remove the csmt key letting wine use its default
#-        set_reg_key(config_key, "Direct3D", L"csmt", NULL);
#+        set_reg_key(config_key, L"Direct3D", L"csmt", NULL);
#     }
# }
#      '')
#    ];
#
#    # yabridge needs this
#    configureFlags = (old.configureFlags or []) ++ [
#      "--enable-win64"
#      "--enable-win32"
#      "--disable-tests"
#    ];

#   makeFlags = (old.makeFlags or []) ++ [
#     "TARGETFLAGS=-m32"
#   ];
# });

  # wine-tkg = prev.wineWowPackages.yabridge.overrideAttrs(old: {
  #     staging = prev.fetchurl {
  #       url = "https://github.com/Kron4ek/wine-tkg/archive/refs/tags/9.21.tar.gz";
  #       sha256 = "sha256-nhn5oRHHB3bue4WY6/gMYxMXv7iJxJiJxkOKCbp4lhY=";
  #     };
  # });

  # TODO her
  # wine-tkg = callPackage ./pkgs/wine-tkg {};

  #wine-tkg = let
  #fetchurl = args@{ url, hash, ... }: prev.fetchurl { inherit url hash; } // args;
  #in fetchurl rec {
  #  # NOTE: This is a pinned version with staging patches; don't forget to update them as well
  #  version = "9.21";
  #  url = "https://dl.winehq.org/wine/source/9.x/wine-${version}.tar.xz";
  #  hash = "sha256-REK0f/2bLqRXEA427V/U5vTYKdnbeaJeYFF1qYjKL/8=";

  #  patches = []
  #  ++ [
  #    (prev.writeText "wine-nix-ssl-cert.patch" ''
  #          diff --git a/dlls/crypt32/unixlib.c b/dlls/crypt32/unixlib.c
  #          index 7cb521eb98b..5804b88be84 100644
  #          --- a/dlls/crypt32/unixlib.c
  #          +++ b/dlls/crypt32/unixlib.c
  #          @@ -654,6 +654,10 @@ static void load_root_certs(void)

  #               for (i = 0; i < ARRAY_SIZE(CRYPT_knownLocations) && list_empty(&root_cert_list); i++)
  #                   import_certs_from_path( CRYPT_knownLocations[i], TRUE );
  #          +
  #          +    char *nix_cert_file = getenv("NIX_SSL_CERT_FILE");
  #          +    if (nix_cert_file != NULL)
  #          +        import_certs_from_path(nix_cert_file, TRUE);
  #           }

  #           static NTSTATUS enum_root_certs( void *args )
  #        '')
  #  ]
  #  ++ [
  #  (fetchpatch {
  #    name = "ntdll-use-signed-type";
  #    url = "https://gitlab.winehq.org/wine/wine/-/commit/fd59962827a715d321f91c9bdb43f3e61f9ebbc.patch";
  #    hash = "sha256-PvFom9NJ32XZO1gYor9Cuk8+eaRFvmG572OAtNx1tks=";
  #  })
  #  (fetchpatch {
  #    name = "winebuild-avoid using-idata-section";
  #    url = "https://gitlab.winehq.org/wine/wine/-/commit/c9519f68ea04915a60704534ab3afec5ec1b8fd7.patch";
  #    hash = "sha256-vA58SfAgCXoCT+NB4SRHi85AnI4kj9S2deHGp4L36vI=";
  #  })
  #];

  #  # see https://gitlab.winehq.org/wine/wine-staging
  #  # staging = prev.fetchurl {
  #  #   url = "https://github.com/Kron4ek/wine-tkg/archive/refs/tags/${version}.tar.gz";
  #  #   hash = "sha256-nhn5oRHHB3bue4WY6/gMYxMXv7iJxJiJxkOKCbp4lhY=";
  #  # };

  #  staging = prev.fetchFromGitHub {
  #    owner = "Kron4ek";
  #    repo = "wine-tkg";
  #    rev = "9.21";
  #    hash = "sha256-nhn5oRHHB3bue4WY6/gMYxMXv7iJxJiJxkOKCbp4lhY=";
  #  };

  #  ## see http://wiki.winehq.org/Gecko
  #  gecko32 = fetchurl rec {
  #    version = "2.47.4";
  #    url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86.msi";
  #    hash = "sha256-Js7MR3BrCRkI9/gUvdsHTGG+uAYzGOnvxaf3iYV3k9Y=";
  #  };
  #  gecko64 = fetchurl rec {
  #    version = "2.47.4";
  #    url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86_64.msi";
  #    hash = "sha256-5ZC32YijLWqkzx2Ko6o9M3Zv3Uz0yJwtzCCV7LKNBm8=";
  #  };

  #  ## see http://wiki.winehq.org/Mono
  #  mono = fetchurl rec {
  #    version = "9.3.0";
  #    url = "https://dl.winehq.org/wine/wine-mono/${version}/wine-mono-${version}-x86.msi";
  #    hash = "sha256-bKLArtCW/57CD69et2xrfX3oLZqIdax92fB5O/nD/TA=";
  #  };
  #};

  # TODO this also fucks with opentrack, and steam?
  # wine-tkg = inputs.nix-gaming.packages.${prev.system}.wine-tkg.override(old: {
  #   version = "9.21";
  #   src = prev.fetchurl {
  #     url = "https://github.com/Kron4ek/wine-tkg/archive/refs/tags/9.21.tar.gz";
  #     sha256 = "sha256-nhn5oRHHB3bue4WY6/gMYxMXv7iJxJiJxkOKCbp4lhY=";
  #   };
  #   ## TODO
  #   # patches = old.patches ++ [
  #   #   ./fix-wchar-staging.patch
  #   # ];
  # });

  # wine-tkg = wineWowPackages.unstableFull.override (old: rec {
  #   pname = "wine-tkg-full";
  #   version = "9.16";
  #   src = fetchFromGitHub {
  #     owner = "Kron4ek";
  #     repo = "wine-tkg";
  #     rev = version;
  #     hash = "sha256-dpW30hIGGw7zl6cmsY1wYHa7T+C4Si+b7s6/8QcHViE=";
  #   };
  # });

  # wine-tkg =
  #   (callPackage ./wine.nix rec {
  #     inherit inputs;
  #     pname = "wine-tkg-full";
  #     version = "9.16";
  #     # ntsync branch
  #     src = fetchFromGitHub {
  #       owner = "Kron4ek";
  #       repo = "wine-tkg";
  #       rev = version;
  #       hash = "sha256-dpW30hIGGw7zl6cmsY1wYHa7T+C4Si+b7s6/8QcHViE=";
  #     };
  #   });

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

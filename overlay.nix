final: prev:

let
  inherit (prev) lib callPackage;
  a = 1;
in {
  # remember to add these files to git for nix to discover them
  neural-amp-modeler-lv2 = callPackage ./pkgs/neural-amp-modeler-lv2 { };

  # gpg 2.4.1 patched to work with .org.gpg
  gnupg_plus_960877b = prev.gnupg.overrideAttrs (orig: {
    patches = (orig.patches or [ ]) ++ [
      (prev.fetchurl {
        url =
          "https://github.com/gpg/gnupg/commit/960877b10f42ba664af4fb29130a3ba48141e64a.diff";
        sha256 = "0pa7rvy9i9w16njxdg6ly5nw3zwy0shv0v23l1mmi0b7jy7ldpvf";
      })
    ];
  });

}

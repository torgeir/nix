{
  lib,
  stdenv,
  fetchgit,
  fetchFromGitHub,
  cmake,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  name = "neural_amp_modeler.lv2";
  version = "0.2.2";

  src = fetchgit {
    url = "https://github.com/mikeoliphant/neural-amp-modeler-lv2";
    rev = "9981fd400509803936d5e40e5b632a111c01dba6";
    # sha256 = lib.fakeHash;
    sha256 = "sha256-Lk/6DV/0zTlnQUFtSWYr7NIxI33b0VyH6DT35aSRo14=";
    fetchSubmodules = true;
  };

  buildInputs = [ cmake ];

  configurePhase = ''
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
  '';

  buildPhase = ''
    make -j4
  '';

  installPhase = ''
    mkdir -p $out
    cp -r neural_amp_modeler.lv2/* $out/
  '';

  meta = with lib; {
    description = "A module for neural amp modeling in LV2";
    homepage = "https://github.com/mikeoliphant/neural-amp-modeler-lv2";
    license = licenses.gpl3;
  };
}

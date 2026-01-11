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
  version = "0.1.3";

  src = fetchgit {
    url = "https://github.com/mikeoliphant/neural-amp-modeler-lv2";
    rev = "43fb036706795332ba2b9ec5fb7099e21c9051df";
    sha256 = "sha256-ls1i30ggZwFoBLxsLYaXSSyKXYYLGU7HtwNXPpSsgUE=";
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

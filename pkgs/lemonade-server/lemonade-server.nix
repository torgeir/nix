{
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  curl,
  zstd,
  cli11,
  httplib,
  libwebsockets,
  nlohmann_json,
  libdrm,
  mbedtls,
}:

stdenv.mkDerivation {
  pname = "lemonade-server";
  version = "10.7.0";

  src = fetchFromGitHub {
    owner = "lemonade-sdk";
    repo = "lemonade";
    rev = "v10.7.0";
    sha256 = "sha256-fB4XKDoX3KLRT8rx6Y3OThhaUuO4ng6rm72OYTtRzjs=";
  };

  postPatch = ''
    find . -name "CMakeLists.txt" -exec sed -i \
      -e 's/if(NOT CMAKE_INSTALL_PREFIX STREQUAL "\/usr")/if(FALSE)/g' \
      -e 's/if(UNIX AND NOT APPLE AND NOT CMAKE_INSTALL_PREFIX STREQUAL "\/usr")/if(FALSE)/g' \
      {} \;
    sed -i 's|DESTINATION /etc/lemonade|DESTINATION etc/lemonade|g' CMakeLists.txt
  '';

  cmakeFlags = [
    "--preset default"
  ];

  postInstall = ''
    ln -s $out/share/lemonade-server/resources $out/bin/resources
  '';

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    curl
    zstd
    cli11
    httplib
    libwebsockets
    nlohmann_json
    libdrm
    mbedtls
  ];
}

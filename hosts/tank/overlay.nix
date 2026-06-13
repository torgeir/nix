{ inputs, pkgs }:
final: prev:

let
  inherit (prev) lib callPackage;
in
{
  lemonade-server = pkgs.callPackage ../../pkgs/lemonade-server/lemonade-server.nix {
    httplib = pkgs.httplib;
  };
}

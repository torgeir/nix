{ config, lib, pkgs, ... }:

{

  
  environment.systemPackages = with pkgs; [
    noson
  ];
  
  networking.firewall = {
    allowedTCPPorts = [ 1400 1401 ];
    allowedUDPPorts = [ 1900 5000 5001 ];
  };
}

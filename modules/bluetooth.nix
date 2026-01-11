{
  config,
  lib,
  pkgs,
  ...
}:

{

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # make xbox controllers able to pair
  hardware.bluetooth.settings = {
    General = {
      # this was already in the config file
      ControllerMode = "dual";
      # this was not, the controllers need a private channel to pair
      Privacy = "device";
    };
  };

}

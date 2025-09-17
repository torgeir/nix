{ pkgs, ... }: {

  # https://nixos.wiki/wiki/Printing

  # canon iX6500 printer

  environment.systemPackages = with pkgs; [
    cups
  ];

  services.printing =  {

   logLevel = "warning";

   enable = true;
   drivers = with pkgs; [
    gutenprint
    # not needed
    # canon-cups-ufr2
    # cnijfilter2
   ];

   # TODO not needed?
   # extraConf = ''
   #   <Location />
   #     Order allow,deny
   #     Allow @LOCAL
   #   </Location>
   #   <Location /admin>
   #     Order allow,deny
   #     Allow @LOCAL
   #   </Location>
   #   <Location /admin/conf>
   #     AuthType Default
   #     Require user @SYSTEM
   #     Order allow,deny
   #     Allow @LOCAL
   #   </Location>
   #  '';

  };

  # TODO untested
  #hardware.printers.ensurePrinters = [
  #  {
  #    name = "canonix6500";
  #    location = "Kontoret";
  #    deviceUri = "usb://Canon/iX6500%20series?serial=007814";
  #    model = "/etc/cups/ppd/Canon_iX6500_series.ppd";
  #    ppdOptions = {
  #      PageSize = "A4";
  #    };
  #  }
  #];

  # - visit https://localhost:631/admin
  # - add printer, driver: Canon iX6500 series - CUPS+Gutenprint v5.3.5 (color)
  # - admin, add allowed users
  # - print test page:
  # > lp -o job-sheets=standard,none -d canon_iX6500_series /dev/null
  # - list drivers
  # > lpinfo -m | grep iX6500
  # gutenprint.5.3://bjc-iX6500-series/expert Canon iX6500 series - CUPS+Gutenprint v5.3.5
  # gutenprint.5.3://bjc-PIXMA-iX6500/expert Canon PIXMA iX6500 - CUPS+Gutenprint v5.3.5
  # - admin page
  # http://localhost:631/printers/Canon_iX6500_series

}

{ config, lib, inputs, pkgs, ... }:

{
  imports = [ inputs.musnix.nixosModules.musnix ];

  musnix.kernel.realtime = true;
  musnix.kernel.packages = pkgs.linuxPackages_6_4_rt;

  # TODO does this work?
  # make helix native activation happy
  environment.etc.machine-id.source = ./machine-id;

  boot.blacklistedKernelModules = [
    # blacklist pci sound card, use usb arturia audiofuse
    "snd_hda_intel"

    # https://discourse.nixos.org/t/how-to-disable-bluetooth/9483
    # blacklist bluetooth
    "bluetooth"
    "btusb"
  ];

  # minimize latency
  # increase frequencies for how often userspace applications can read from timekeeping devices
  # also lower pci latency for thunderbolt devices
  boot.postBootCommands = ''
    #!/bin/bash
    echo 2048 > /sys/class/rtc/rtc0/max_user_freq
    echo 2048 > /proc/sys/dev/hpet/max-user-freq

    setpci -v -d *:* latency_timer=b0
    for p in $(lspci | grep -i thunderbolt | awk '{print $1}'); do
      setpci -v -s $p latency_timer=ff
    done
  '';

  # check what is set with
  #   cat /proc/cmdline
  boot.kernelParams = [
    # realtime audio tuning for preemt_dynamic kernels
    # maybe not needed for rt kernels?
    "preemt=full"
  ];

  # realtime audio
  boot.kernel.sysctl = { "vm.swappiness" = 10; };

  # disable wifi
  networking.wireless.enable = false;

  # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Performance-tuning
  # https://linuxmusicians.com/viewtopic.php?t=25556
  # https://github.com/chmaha/ArchProAudio
  # https://nixos.wiki/wiki/PipeWire
  #   pw-dump to check pipewire config
  #   systemctl --user status pipewire wireplumber
  #   systemctl --user restart pipewire wireplumber
  services.pipewire = {
    enable = true;
    audio.enable = true;
    wireplumber.enable = true;
    alsa.enable = true; # alsa support
    pulse.enable = true; # pipewire pulse emulation

    # if you launch jack manually (non pipewire)
    #   jackd -R -P 99 -d alsa -d hw:AudioFuse,0 -r 48000 -p 168 -n 3
    #   for p in $(ps -eLo pid,cmd | grep -i jack | grep -v grep | awk '{print $1}'); do chrt -f -p 99 $p; done
    jack.enable = true; # pipewire jack emulation
  };

  # adjust pipewire settings at runtime
  #   pw-metadata -n settings 0 clock.force-quantum 512
  #
  # this sets the realtime priority for a list of pids, it is no longer needed
  # after rtkit was adjusted to handle pipewire, also 99 is probably too high
  #   for p in $(ps -eLo pid,cmd | grep -i pipewire | grep -v grep | awk '{print $1}'); do sudo chrt -f -p 99 $p; done

  # jack
  #
  # ~direct monitoring, some pops
  #   pw-metadata -n settings 0 clock.force-quantum 48
  # reasonable latency, few/no pops
  #   pw-metadata -n settings 0 clock.force-quantum 480
  #
  # https://linuxmusicians.com/viewtopic.php?t=26271
  #
  # flip reaper audio system over to DummyAudio and back to Jack
  # after adjusting these. Also remember to
  #   systemctl --user restart pipewire wireplumber
  environment.etc."/pipewire/jack.conf.d/override.conf".text = ''
    jack.properties = {
      # node.force-quantum = 48 # 0.001s, given alsa rate 48000
      # node.force-quantum = 144 # 0.003s
      # node.force-quantum = 240 # 0.005s
      # node.force-quantum = 384 # 0.008s
      node.force-quantum = 480 # 0.01s
    }
  '';

  environment.etc."wireplumber/main.lua.d/98-alsa-no-pop.lua".text = ''
    table.insert(alsa_monitor.rules, {
      matches = {
        {
          -- { "node.name", "matches", "alsa_output.*" },
          { "node.name", "matches", "alsa_output.usb-ARTURIA_AudioFuse*" },
        },
      },
      apply_properties = {

        -- keep it alive
        ["session.suspend-timeout-seconds"] = 0,
        ["suspend-node"] = false,
        ["node.pause-on-idle"] = false,

        -- pipewire docs: ALSA Buffer Properties:
        -- It removes the extra delay added of period-size/2 if the device can
        -- support this. for batch devices it is also a good idea to lower the
        -- period-size (and increase the IRQ frequency) to get smaller batch
        -- updates and lower latency.
        ["api.alsa.disable-batch"] = true,

        -- pipewire docs: Change node priority:
        -- Device priorities are usually from 0 to 2000.
        ["priority.session"] = 3000,

        -- pipewire docs: ALSA Buffer Properties
        -- extra delay between hardware pointers and software pointers
        --["api.alsa.headroom"] = 0,

        ["api.alsa.rate"] = 48000,

        --["api.alsa.period-size"] = 168,
        --["api.alsa.period-size"] = 256,
        --["api.alsa.period-size"] = 512,
        ["api.alsa.period-size"] = 1024,

        ["api.alsa.period-num"] = 3,
      },
    })
  '';

  # ensure realtime processes don't hang the machine
  services.das_watchdog.enable = true;

  # help reaper control cpu latency, when you start it from audio group user
  # control power mgmt from userspace (audio) group
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
  services.udev.extraRules = ''
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
  '';

  # force full perf cpu mode
  # cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  powerManagement.cpuFreqGovernor = "performance";

  # Tese settings go well with reaper
  #   Thread priority: Time Critical
  #   Behavior: 15 - Very Aggressive
  #   Anticipate FX processing [x]
  #   Allow live FX processing [2 CPUs] on the 5950x
  #
  # enable realtime kit, so that pipewire's realtime priority can be adjusted automatically
  # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Performance-tuning#rtkit
  security.rtkit.enable = true;
  systemd.services.rtkit-daemon.serviceConfig.ExecStart = [
    ""
    "${pkgs.rtkit}/libexec/rtkit-daemon --scheduling-policy=FIFO --our-realtime-priority=89 --max-realtime-priority=88 --min-nice-level=-19 --rttime-usec-max=2000000 --users-max=100 --processes-per-user-max=1000 --threads-per-user-max=10000 --actions-burst-sec=10 --actions-per-burst-max=1000 --canary-cheep-msec=30000 --canary-watchdog-msec=60000"
  ];

  # firefox about:config, disable cpu heavy tasks
  #   reader.parse-on-load.enabled false
  #   media.webspeech.synth.enabled false

  # realtime priority for usb sound card, and peg interrupts to one cpu
  systemd.services.adjust-sound-card-irqs = {
    description = "IRQ thread tuning for realtime kernels";
    after = [ "multi-user.target" "sound.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ nix gawk gnugrep gnused procps ];
    serviceConfig = {
      User = "root";
      # run it once
      Type = "oneshot";
      # its ok that it exits
      RemainAfterExit = true;
      ExecStart = pkgs.writers.writeBash "adjust-sound-card-irqs" ''
        # https://www.reddit.com/r/linuxaudio/comments/8isvxn/comment/dywjory/
        # run xhci_hcd driver (extensible host controller interface, used for
        # usb 3.0) with real time priority on cpu 2
        # check it with top -c 0.2

        pidof_xhci=$(ps -eLo pid,cmd | grep -i xhci | head -1 | awk '{print $1}')
        intof_xhci=$(cat /proc/interrupts | grep xhci_hcd | cut -f1 -d: | sed s/\ //g)

        # set realtime priority for all pids
        PATH=/run/current-system/sw/bin/:$PATH chrt -f -p 99 $pidof_xhci

        # peg them on a single cpu
        cpu=10
        PATH=/run/current-system/sw/bin:$PATH taskset -cp $cpu $pidof_xhci
        for i in $intof_xhci; do
          echo $cpu > /proc/irq/$i/smp_affinity
          cat /proc/irq/$i/smp_affinity

          echo $cpu > /proc/irq/$i/smp_affinity_list
          cat /proc/irq/$i/smp_affinity_list
        done
      '';
    };
  };

  # allow realtime for pipewire and user audio group
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "98";
    }
    {
      domain = "@audio";
      item = "nice";
      type = "-";
      value = "-11";
    }
    {
      domain = "@pipewire";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@pipewire";
      item = "rtprio";
      type = "-";
      value = "98";
    }
    {
      domain = "@pipewire";
      item = "nice";
      type = "-";
      value = "-11";
    }
  ];

  environment.systemPackages = with pkgs;
    [
      # don't really need this?
      # irqbalance
    ];

  # services.irqbalance.enable = true;
}

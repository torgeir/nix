{ config, lib, inputs, pkgs, nixpkgs, ... }: {

  imports = [ inputs.musnix.nixosModules.musnix ];

  # realtime kernel
  #musnix.kernel.realtime = true;
  #musnix.kernel.packages = pkgs.linuxPackages_6_11_rt;
  # torgeir: removed musnix rtirq, postcommandscript does the same better
  #
  # or, latest kernels has realtime audio improvements
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

  # make helix native activation happy
  environment.etc.machine-id.source = ./machine-id;
  # Chatgpt suggests this instead
  # # Use systemd.tmpfiles.rules to create the symlink
  # systemd.tmpfiles.rules = [
  #   "L /etc/machine-id - - - - /var/lib/dbus/machine-id"
  # ];

  # # Ensure the /var/lib/dbus/machine-id has the correct content
  # environment.etc."var/lib/dbus/machine-id".text =
  #   builtins.readFile /path/to/your/static/machine-id;

  boot.blacklistedKernelModules = [
    # blacklist pci sound card, use usb arturia audiofuse
    "snd_hda_intel"

    # https://discourse.nixos.org/t/how-to-disable-bluetooth/9483
    # blacklist bluetooth
    # "bluetooth"
    # "btusb"

    # blacklist wifi
    "cfg80211"
  ];

  # minimize latency
  # also prioritize the pid and interrupts of the sound card
  boot.postBootCommands = ''
    #!/usr/bin/env bash

    # fix nix paths
    export PATH=/run/current-system/sw/bin/:$PATH

    priority=94
    irq=$(cat /proc/interrupts | grep "xhci_hcd" | awk '{sum=0; for(i=2;i<=NF-3;i++) sum+=$i; print sum, $1}' | sort -nr | head -1 | awk '{gsub(/:/, "", $2); print $2}')
    pid=$(pgrep irq/$irq-)
    thread=$(ps -eo comm | grep irq/$irq-)

    logger -p user.info "[realtime audio]: setting priority to $priority for soundcard irqs pid $pid, thread $thread."
    chrt -f -p $priority $pid

    # Spread across CPUs 24-31 (last CCD on 5950X)
    cpus="24-27"
    logger -p user.info "[realtime audio]: spreading soundcard irqs $pid on thread $thread to cpus $cpus."

    echo $cpus > /proc/irq/$irq/smp_affinity_list
    logger -p user.info "[realtime audio] smp_affinity_list for irq $irq is now $(cat /proc/irq/$irq/smp_affinity_list)"
  '';

  # check what is set with
  #   cat /proc/cmdline
  boot.kernelParams = [
    # make threads out of irqs, for preemt_dynamic kernels
    "threadirqs"
    # not needed for rt kernels
    "preemt=full"

    "isolcpus=24-27"     # Isolate 4 CPUs for audio IRQs
    "nohz_full=24-27"
    "rcu_nocbs=24-27"
    "irqaffinity=0-23"   # Keep other IRQs on otther cpus

  ];

  # limit swappiness, but really i use zram instead
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
    package = pkgs.pipewire;
    enable = true;
    audio.enable = true;
    wireplumber.enable = true;
    alsa.enable = true; # alsa support
    pulse.enable = true; # pipewire pulse emulation
    jack.enable = true; # pipewire jack emulation
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/main.lua.d/98-alsa-no-pop.lua" ''
        table.insert(alsa_monitor.rules, {
          matches = {
            {
              -- run pw-top to see the names
              { "node.name", "matches", "alsa_input.usb-LINE_6_HELIX*" },
              { "node.name", "matches", "alsa_output.usb-LINE_6_HELIX*" },
            },
          },
          apply_properties = {
            -- keep it alive
            ["session.suspend-timeout-seconds"] = 0,
            ["suspend-node"] = false,
            ["node.pause-on-idle"] = false,
            ["api.alsa.disable-batch"] = true,
            ["priority.session"] = 3000,
            ["api.alsa.rate"] = 48000,
            ["api.alsa.period-size"] = 128,
          }
        })

        table.insert(alsa_monitor.rules, {
          matches = {
            {
              -- run pw-top to see the names
              { "node.name", "matches", "alsa_input.usb-ARTURIA_AudioFuse*" },
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
            ["api.alsa.headroom"] = 32,

            -- Interface: Arturia Audiofuse
            -- Reaper using alsa only can do this, without any pops;
            --   Rate 48000
            --   Size 64
            --   Periods 3

            -- https://wiki.linuxaudio.org/wiki/list_of_jack_frame_period_settings_ideal_for_usb_interface
            ["api.alsa.rate"] = 48000,
            ["api.alsa.period-num"] = 3,
            -- experiments
            --["api.alsa.period-size"] = 48, -- and run reaper with PIPEWIRE_LATENCY=48/48000 reaper, this gives 1ms latency
            ["api.alsa.period-size"] = 128,
            --["api.alsa.period-size"] = 168,
            --["api.alsa.period-size"] = 144,
            --["api.alsa.period-size"] = 160,
            --["api.alsa.period-size"] = 256,
          },
        })
      '')
    ];
  };

  # jack
  #
  # adjust pipewire settings at runtime
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
      node.force-quantum = 48 # 0.001s, given alsa rate 48000
      # node.force-quantum = 128 # 0.0026s
      # node.force-quantum = 144 # 0.003s
      # node.force-quantum = 240 # 0.005s
      # node.force-quantum = 288 # 0.006s
      # node.force-quantum = 384 # 0.008s
      # node.force-quantum = 480 # 0.01s
    }
  '';

  # help reaper control cpu latency, when you start it from audio group user
  # control power mgmt from userspace (audio) group
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
  #
  # Run "udevadm monitor" and do what you want to monitor, e.g. plug something
  services.udev.extraRules = ''
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"

    # set scheduler for nvme
    # cat /sys/block/*/queue/scheduler
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"

    # restart dhcpcd on sleep wake
    ACTION=="remove", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="1c75", ATTRS{idProduct}=="af02", RUN+="${pkgs.systemd}/bin/systemctl --no-block stop dhcpcd.service"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="1c75", ATTRS{idProduct}=="af02", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart dhcpcd.service"

    # prevent ps4 touchpad acting as mouse
    # usb
    #ACTION=="add|change", ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    # bluetooth
    #ACTION=="add|change", ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  # force full perf cpu mode
  # cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  # obs: corecontrol also controls this
  powerManagement.cpuFreqGovernor = "performance";

  # These settings go well with reaper
  #   Thread priority: Highest (recommended)
  #   Behavior: 8 - Aggressive
  #   Anticipate FX processing [x]
  #   Allow live FX processing off (5950x)
  #
  # enable realtime kit, so that pipewire's realtime priority can be adjusted automatically
  # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Performance-tuning#rtkit
  # rtkit != rtirq
  security.rtkit.enable = true;
  systemd.services.rtkit-daemon.serviceConfig.ExecStart = [
    ""
    # claude raised max-realtime-priority from 88 to 94
    "${pkgs.rtkit}/libexec/rtkit-daemon --scheduling-policy=FIFO --our-realtime-priority=89 --max-realtime-priority=94 --min-nice-level=-19 --rttime-usec-max=2000000 --users-max=100 --processes-per-user-max=1000 --threads-per-user-max=10000 --actions-burst-sec=10 --actions-per-burst-max=1000 --canary-cheep-msec=30000 --canary-watchdog-msec=60000"
  ];

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

  environment.systemPackages = with pkgs; [
    perf

    cpuset

    sysstat # iostat etc
    iotop # e.g. sudo iotop -d 0.1 -a
    lsof # e.g. lsof -p $(pidof wineserver)

    jalv
    lilv # provides tools like lv2ls

    # piano
    # 2025 funker ikke med siste nix-unstable
    # 20250115 ingen av disse to virker
    # 20250125 stable funker
    pkgs.stable.linuxsampler # add lv2 path /run/current-system/sw/lib/lv2/ to reaper, rescan
    qsampler # launch this and add channel, select plugin and the .gig piano file

    (writeScriptBin "reaper-pw"
      "pw-metadata -n settings 0 clock.force-quantum $1")
    (writeScriptBin "reaper-pw-48"
      "pw-metadata -n settings 0 clock.force-quantum 48")
    (writeScriptBin "reaper-pw-144"
      "pw-metadata -n settings 0 clock.force-quantum 144")
    (writeScriptBin "reaper-pw-256"
      "pw-metadata -n settings 0 clock.force-quantum 256")
    (writeScriptBin "reaper-pw-512"
      "pw-metadata -n settings 0 clock.force-quantum 512")
  ];
  # https://magazine.odroid.com/article/setting-irq-cpu-affinities-improving-irq-performance-on-the-odroid-xu4/
  # services.irqbalance.enable = true;

  environment.variables = {
    DSSI_PATH =
      "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
    LADSPA_PATH =
      "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
    LV2_PATH =
      "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
    LXVST_PATH =
      "$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
    VST_PATH =
      "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
  };
}

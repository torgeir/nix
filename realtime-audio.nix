{ config, lib, inputs, pkgs, nixpkgs, ... }: {

  imports = [ inputs.musnix.nixosModules.musnix ];

  # realtime kernel
  musnix.kernel.realtime = true;
  musnix.kernel.packages = pkgs.linuxPackages_6_6_rt;
  # musnix.rtirq.nameList = "xhci_hcd";
  # musnix.rtirq.enable = true;
  #
  # or, latest kernel has realtime audio improvements
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;

  # permission denied when creating cpuset.cpus
  # https://www.reddit.com/r/NixOS/comments/158azri/changing_user_slices_cgroup_controllers/
  # TODO gjør at cset shield --cpu 7 -kthread=on ikke virker?
  # systemd.services."user@".serviceConfig.Delegate = "memory pids cpu cpuset";

  # TODO does this work?
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
    "bluetooth"
    "btusb"

    # blacklist wifi
    "cfg80211"
  ];

  # shield processes on certain cpus
  #   for p in $(ps -eo pid,comm | grep -E '(yabridge|reaper)' | grep -v grep |awk '{print $1}'); do sudo chrt -f -p 92 $p; done
  #   sudo cset shield --cpu 16-31 --kthread=on
  #   sudo cset shield --force --shield --pid $(ps xa | grep -E '(reaper|yabridge)' | grep -v "oom" | grep -v grep |awk '{print $1}' | cut -d" " -f1 | paste -s -d,)
  #
  # https://linuxmusicians.com/viewtopic.php?f=27&t=20419
  # cgroups https://developers.redhat.com/blog/2015/09/21/controlling-resources-with-cgroups-for-performance-testing#rhel_7
  # https://discuss.linuxcontainers.org/t/what-is-the-best-way-to-use-numactl-or-taskset-and-chrt-in-lxd-which-cpus-are-isolated-from-the-host/7641/7

  # minimize latency
  # increase frequencies for how often userspace applications can read from timekeeping devices
  # also prioritize the pid and interrupts of the sound card
  boot.postBootCommands = ''
    #!/bin/bash
    echo 2048 > /sys/class/rtc/rtc0/max_user_freq
    echo 2048 > /proc/sys/dev/hpet/max-user-freq

    # let realtime processes dominate cpu indefinitely
    echo -1 > /proc/sys/kernel/sched_rt_runtime_us

    # fix nix paths
    export PATH=/run/current-system/sw/bin/:$PATH

    # https://rigtorp.se/low-latency-guide/
    # sudo sh -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
    echo never > /sys/kernel/mm/transparent_hugepage/enabled

    # poor mans rtirqs
    # the irq number below is the fastest increasing counter when running
    #   watch -n0.1 'cat /proc/interrupts'
    #
    ## ends up as -95
    ## needs to be higher than reaper
    ## reaper+yabridge-host needs to be higher than pipewire+wireplumber
    priority=94
    irq=85
    pid=$(pgrep irq/$irq-)
    thread=$(ps -eo comm | grep irq/$irq-)

    # increase the pids realtime priority
    logger -p user.info "[realtime audio]: setting priority to $priority for $pid, thread $thread."
    chrt -f -p $priority $pid

    cpu=16
    # pin to single cpu
    logger -p user.info "[realtime audio]: pinning $pid on thread $thread to cpu $cpu."
    taskset -cp $cpu $pid

    echo $cpu > /proc/irq/$irq/smp_affinity
    logger -p user.info "[realtime audio] smp_affinity for irq $irq is now $(cat /proc/irq/$irq/smp_affinity)"

    echo $cpu > /proc/irq/$irq/smp_affinity_list
    logger -p user.info "[realtime audio] smp_affinity_list for irq $irq is now $(cat /proc/irq/$irq/smp_affinity_list)"

    # unused, for irqbalance:
    #   one bit per cpu: 0000 0000 1100 0000 => 00c0 in hex
    #export IRQBALANCE_BANNED_CPUS="00c0"
  '';

  # check what is set with
  #   cat /proc/cmdline
  boot.kernelParams = [
    # make threads out of irqs, for preemt_dynamic kernels
    "threadirqs"
    # not needed for rt kernels
    "preemt=full"
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
    enable = true;
    audio.enable = true;
    wireplumber.enable = true;
    alsa.enable = true; # alsa support
    pulse.enable = true; # pipewire pulse emulation
    jack.enable = true; # pipewire jack emulation

    # force pipewire 1.0, its still in nix staging
    # inspired by
    #   https://github.com/K900/nixpkgs/commit/32c52236b2d84280395e2115191ed8411a93a049
    #   https://github.com/K900/nixpkgs/commit/f3ee548e96fae8919ab8ca0944e08fa64f6314d3
    package = (pkgs.pipewire.override { rocSupport = false; }).overrideAttrs
      (old: rec {
        version = "1.0.0";
        src = pkgs.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "pipewire";
          repo = "pipewire";
          rev = version;
          sha256 = "sha256-mfnMluxJAxDbB6JlIM6HJ0zg7e1q3ia3uFbht6zeHCk=";
        };
        mesonFlags = old.mesonFlags ++ [ "-Dman=enabled" ];
        postUnpack = ''
          patchShebangs source/doc/*.py
          patchShebangs source/doc/input-filter-h.sh
        '';
      });
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
      # node.force-quantum = 144 # 0.003s
      # node.force-quantum = 240 # 0.005s
      # node.force-quantum = 288 # 0.006s
      # node.force-quantum = 384 # 0.008s
      # node.force-quantum = 480 # 0.01s
    }
  '';

  environment.etc."wireplumber/main.lua.d/98-alsa-no-pop.lua".text = ''
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
        ["api.alsa.disable-batch"] = false,
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
        ["api.alsa.disable-batch"] = false,

        -- pipewire docs: Change node priority:
        -- Device priorities are usually from 0 to 2000.
        ["priority.session"] = 3000,

        -- pipewire docs: ALSA Buffer Properties
        -- extra delay between hardware pointers and software pointers
        ["api.alsa.headroom"] = 64,

        -- ???
        -- Interface: Arturia Audiofuse
        -- Reaper using alsa only can do this, without any pops;
        --   Rate 48000
        --   Size 168
        --   Periods 3
        -- ???

        -- https://wiki.linuxaudio.org/wiki/list_of_jack_frame_period_settings_ideal_for_usb_interface
        ["api.alsa.rate"] = 48000,

        ["api.alsa.period-num"] = 3,
        --["api.alsa.period-num"] = 2,

        ["api.alsa.period-size"] = 168, -- and run reaper with PIPEWIRE_LATENCY=384/48000 reaper, this gives 8ms latency

        -- experiments
        --["api.alsa.period-size"] = 128,
        --["api.alsa.period-size"] = 144,
        --["api.alsa.period-size"] = 160,
        --["api.alsa.period-size"] = 256,
      },
    })
  '';

  # help reaper control cpu latency, when you start it from audio group user
  # control power mgmt from userspace (audio) group
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
  services.udev.extraRules = ''
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"

    # set scheduler for nvme
    # cat /sys/block/*/queue/scheduler
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # force full perf cpu mode
  # cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  powerManagement.cpuFreqGovernor = "performance";

  # These settings go well with reaper
  #   Thread priority: Highest (recommended)
  #   Behavior: 8 - Aggressive
  #   Anticipate FX processing [x]
  #   Allow live FX processing off (5950x)
  #
  # Thread priorities needs to be
  #   1. xhci_hcd (e.g. 95)
  #   2. reaper + yabridge (e.g. 92)
  #   3. pipewire + wireplumber (e.g. 89)
  #
  # bump their priority
  #   for p in $(ps -eo pid,comm | grep -E '(yabridge|reaper)' | awk '{print $1}'); do sudo chrt -f -p 91 $p; done
  # bring them to the same cpu
  #   for p in $(ps -eo pid,comm | grep -E '(yabridge|reaper)' | awk '{print $1}'); do sudo taskset -cp 3 $p; done
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
  #
  # TODO
  # pgrep -f -w firefox | xargs renice --relative 5 {}

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
    # don't really need this?
    # irqbalance

    cpuset

    sysstat # iostat etc
    iotop # e.g. sudo iotop -d 0.1 -a
    lsof # e.g. lsof -p $(pidof wineserver)
  ];
  # https://magazine.odroid.com/article/setting-irq-cpu-affinities-improving-irq-performance-on-the-odroid-xu4/
  # services.irqbalance.enable = true;
}

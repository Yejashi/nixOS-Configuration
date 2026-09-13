# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];



  boot = {
    # Get latest kernel
    #kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxPackages_6_12;

    initrd.kernelModules = [ "amdgpu" ];

    loader = {
      systemd-boot = {
        enable = true;
        #devices = [ "/dev/vda" ];
        #useOSProber = true;
        # You can have at most 5 nixos configurations at a time
        configurationLimit = 5;
      };
      timeout = 5;
    };
  };


  # Switched to AMD (RX 6750 XT) -- see hardware.graphics below. Left here
  # in case of a future switch back to nvidia.
  # hardware.nvidia = {
  #
  #   # Modesetting is required.
  #   modesetting.enable = true;
  #
  #   nvidiaPersistenced = true;
  #   # prime = {
  #   #     offload.enable = true;
  #   #     #sync.enable = true;
  #
  #   #     # amdgpuBusId = "PCI:5:0:0";
  #
  #   #     # nvidiaBusId = "PCI:1:0:0";
  #   # };
  #
  #   # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
  #   # Enable this if you have graphical corruption issues or application crashes after waking
  #   # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
  #   # of just the bare essentials.
  #   powerManagement.enable = false;
  #
  #   # Fine-grained power management. Turns off GPU when not in use.
  #   # Experimental and only works on modern Nvidia GPUs (Turing or newer).
  #   # powerManagement.finegrained = false;
  #
  #   # Use the NVidia open source kernel module (not to be confused with the
  #   # independent third-party "nouveau" open source driver).
  #   # Support is limited to the Turing and later architectures. Full list of
  #   # supported GPUs is at:
  #   # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
  #   # Only available from driver 515.43.04+
  #   # Currently alpha-quality/buggy, so false is currently the recommended setting.
  #   open = false;
  #
  #   # Enable the Nvidia settings menu,
  #   # accessible via `nvidia-settings`.
  #   nvidiaSettings = true;
  #
  #   # Optionally, you may need to select the appropriate driver version for your specific GPU.
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # needed for Steam/Proton (32-bit Vulkan/OpenGL)
  };




  networking.hostName = "yejashi"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services = {
    xserver = {
      # Enable the X11 windowing system.
      enable = true;

      videoDrivers = [ "amdgpu" ];

      windowManager.i3 = {
        extraPackages = with pkgs; [
          # Add pkgs here
        ];

      };

    };

    displayManager = {
      gdm = {
        enable = true;

        # Keep the machine awake at the login screen so remote access
        # remains available after reboot.
        autoSuspend = false;
      };
    };

    desktopManager = {
      # Enable the GNOME Desktop Environment.
      gnome = {
          enable = true;
          extraGSettingsOverridePackages = [ pkgs.mutter ];
          extraGSettingsOverrides = ''
              [org.gnome.mutter]
              edge-tiling=true
          '';
      };
    };

    avahi = {
        enable = true;
        nssmdns4 = true;
        # Avoid advertising this workstation to the campus Wi-Fi network.
        openFirewall = false;
    };

    pulseaudio.enable = false;
  };


  services.tailscale = {
    enable = true;
    openFirewall = false;

    # Do not let Tailscale replace the system's DNS configuration.
    # NetworkManager/DHCP should provide DNS for the active network.
    extraSetFlags = [
      "--accept-dns=false"
    ];
  };
  services.openssh = {
    enable = true;
    openFirewall = false;

    settings = {
      # The campus network cannot route directly to this private host. Tailscale
      # provides the network boundary; SSH then authenticates the local account
      # with its password.
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = false;
      AuthenticationMethods = "password";
      PermitRootLogin = "no";
      AllowUsers = [ "yejashi" ];

      MaxAuthTries = 3;
      LoginGraceTime = 30;
      LogLevel = "VERBOSE";

      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "local";
      GatewayPorts = "no";
      PermitTunnel = "no";
    };
  };

  networking.firewall = {
    enable = true;
    # 22: SSH. 3389: GNOME Remote Login (system daemon, headless session).
    # 3390: GNOME Desktop Sharing (user daemon, mirrors the seat0 session) --
    # moved off the default because both backends bind 3389 otherwise.
    # 4096: opencode-server, for checking and steering a run from a phone.
    # All reachable only over Tailscale; the campus network cannot route here.
    interfaces."tailscale0".allowedTCPPorts = [ 22 3389 3390 4096 ];
  };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.enableAllFirmware = true;

  #sound = {
   # enable = true;
    #mediaKeys.enable = true;
  #};

  hardware.bluetooth = {
    enable = true;
    #hsphfpd.enable = true; # Conflicts with WirePlumber
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.yejashi = {
    isNormalUser = true;
    description = "yejashi";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "storage"
      "network"
      "lp"
    ];
    # initialPassword = "password";
    packages = with pkgs; [
      #  thunderbird
    ];
  };
  
  # Esoteric Crap Setup
  #services.xserver.windowManager.i3.enable = true;



  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    zlib 
    libgcc  
  ];

  # Install firefox.
  programs.firefox.enable = true;
  programs.steam.enable = true;
  services.input-remapper.enable = true;
  services.flatpak.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Broken upstream (sphinx build failure on python3.12's own docs as of
  # nixos-26.05), and we don't use the HTML/info doc trees anyway. man
  # pages (documentation.man.enable) are unaffected.
  documentation.doc.enable = false;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    curl
    zip
    unzip
    vim
    git
    usbutils
    v4l-utils
    killall
    linuxPackages.v4l2loopback
    ffmpeg
    sshfs
    nix-ld
    python312
    python312Packages.ipykernel
    python312Packages.pillow
    python312Packages.jupyter-core
    python312Packages.cython
    virtualenv
    gcc
    conda
    system-config-printer

    # AMD Vulkan inference diagnostics and AppImage compatibility
    vulkan-tools
    mesa-demos
    clinfo
    nvtopPackages.amd
    appimage-run

    # Gnome Packages
    gnome-tweaks
    kitty-themes

    # Icons + Themes
    tela-circle-icon-theme
    orchis-theme
    material-icons
    material-design-icons
    # oranchelo-icon-theme

    gnumake
    kitty
    thunar
    vscode
    starship
    input-remapper
    inputs.zen-browser.packages."x86_64-linux".default 
    flatpak
    gst_all_1.gst-plugins-rs
    # flatpak-builder
    # Add zen-browser later on
  ];

  # TODO: Find a way to fix neofetch icons
  fonts.packages = with pkgs; [
    oranchelo-icon-theme
    source-code-pro
    noto-fonts
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
    cantarell-fonts
    mononoki
  ];

  # Can't do this in home-manager for some reason, bummer
  programs.starship = {
    enable = true;
    interactiveOnly = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      # add_newline = false;

      # character = {
      #   success_symbol = "[➜](bold green)";
      #   error_symbol = "[➜](bold red)";
      # };

      # package.disabled = true;
    };

    presets = [ "tokyo-night" ];
  };

  # Local LLM inference server (Qwen3.6-35B-A3B MoE, IQ4_XS + Q8 MTP head)
  # on the RX 6750 XT via Vulkan. Package comes from the unstable overlay in
  # flake.nix -- see the comment there for why stable's llama-cpp won't do.
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;

    # Deliberately NOT under ~/.local/share: the upstream module hardens the
    # unit with DynamicUser + ProtectHome=true, so /home is invisible to the
    # service. The model lives in /var/lib/llama-models instead.
    model = "/var/lib/llama-models/Qwen3.6-35B-A3B-MTP-IMAT-IQ4_XS-Q8nextn.gguf";
    host = "127.0.0.1";
    port = 8080;

    extraFlags = [
      # 64K context at q8_0 KV costs the same VRAM as 128K at q4_0 but has
      # half the cache error. Observed peak use is ~12K tokens, so the
      # larger context was never actually being used.
      "-c" "65536"
      "-fa" "on"
      "-ctk" "q8_0"
      "-ctv" "q8_0"

      # Physical batch; default 512. Larger amortises the CPU-side expert
      # gather, which is what makes prefill decay at long context (measured
      # 335 t/s at 2-5k prompts down to 178 t/s at 20-30k). Costs VRAM on top
      # of --n-cpu-moe, so these two compete: if the service stops starting,
      # this is the first thing to drop back to 512.
      "-ub" "1024"

      # Whole transformer on the GPU; the experts of 24 of 41 MoE layers stay
      # in system RAM so the remainder fits in 12GB of VRAM. Experts cost
      # 408 MiB/layer, so each -1 here is +408 MiB VRAM; 24 lands at ~9.9GB.
      # Assumes this seat runs only the GDM greeter -- a real GNOME session
      # needs that headroom back, so raise this to 27 before using the desktop.
      "-ngl" "999"
      "--n-cpu-moe" "24"
      "--load-mode" "none"
      "--fit" "off"

      # MTP-head speculative decoding, roughly 2x generation throughput
      # (19 tok/s measured without it, ~32 tok/s with, at 0.85 draft
      # acceptance).
      #
      # These were briefly removed on 2026-09-13 while chasing agent
      # "looping", on the theory that upstream issues #23335 / #23302
      # (draft-mtp altering the committed token stream on Qwen3.6 MTP
      # models) explained it. They did not: the culprit was the DRY sampler
      # corrupting verbatim-repeated file paths -- see the DRY note below.
      # Removing MTP alone did NOT stop the corruption; removing DRY did.
      # Restored here once DRY-off was confirmed clean over a real session.
      #
      # #23335 / #23302 are still open and unconfirmed, so if token-stream
      # weirdness ever appears that DRY does not explain, these are still
      # the first three lines to pull.
      # n-max was 6 and measured mean accepted len 5.88 -- saturating the cap,
      # not the model. Raised to 10; if acceptance drops much below ~0.85,
      # walk it back. Check with: journalctl -u llama-cpp | grep 'draft acceptance'
      "--spec-type" "draft-mtp"
      "--spec-draft-n-max" "10"
      "--spec-draft-p-min" "0.6"

      "--jinja"
      "--reasoning-preserve"

      # Qwen3.6's published sampler spec for "thinking mode, precise coding"
      # is temp 0.6 / top-p 0.95 / top-k 20 / min-p 0.0 / presence-penalty 0.
      # top-k already arrives as 20 from the GGUF's own metadata, and
      # presence-penalty is 0 by default -- note Qwen only recommends the
      # aggressive presence-penalty 1.5 for general chat, NOT for coding.
      # min-p is the one that does not match: llama.cpp defaults it to 0.05.
      # 0.0 is what Qwen publishes, so it stays -- but note the original
      # justification for it (leaving tail mass available for DRY to escape
      # a repeat) is void now that DRY is off, and that same tail is what
      # let DRY's miscased path variants get sampled. If path corruption is
      # ever seen again with DRY already off, try 0.05 here next.
      "--min-p" "0.0"
      # OpenCode sends its own temperature per request, which overrides this;
      # it only applies to clients that send none.
      "--temp" "0.6"

      # DRY is DISABLED (2026-09-13). It was:
      #
      #   "--dry-multiplier" "0.8"
      #   "--dry-base" "1.75"
      #   "--dry-allowed-length" "8"
      #   "--dry-penalty-last-n" "4096"
      #
      # The old note here claimed "repeated code lines are unaffected"
      # because DRY only penalises an 8+ token verbatim repeat. That
      # reasoning is wrong for agent workloads: an absolute path like
      # /home/yejashi/Documents/repos/nixOS-Configuration/users/yejashi/home.nix
      # is ~20 tokens and a coding agent reproduces it verbatim on every
      # tool call, so within a few calls it becomes exactly the pattern DRY
      # suppresses. It then corrupts the path -- observed: Users, USERS,
      # nixOS-CONFIGURATION, Configurations, NixOS-Confguration -- the read
      # fails, the agent retries, and that retry storm is the "looping".
      # min-p 0.0 below made it worse by leaving the miscased variants in
      # the distribution for sampling.
      #
      # A/B measured over a 25-message transcript, 3 trials, sampler as the
      # only variable: DRY on reproduced the path exactly 0/3 times with
      # miscased segments every trial; DRY off, 3/3 exact and 0 corruption.
      #
      # Confirmed in a real OpenCode session: with DRY off (and MTP still
      # off at that point) the corruption stopped, which is what cleared
      # draft-mtp and let it be restored above. DRY was originally added to
      # cure "degenerate loops", so it was most likely causing the thing it
      # was meant to fix.
      #
      # Do not reintroduce ANY repetition penalty here (DRY, repeat-penalty,
      # presence-penalty). Agents must emit identical paths, identifiers and
      # tool names constantly; penalising verbatim repeats is actively wrong
      # for this workload. Qwen's own spec says presence-penalty 1.5 is for
      # general chat and NOT for coding, for the same reason.
      # Host-memory prompt cache: what lets the orchestrator rotate workers
      # through the single slot without re-prefilling each switch. KV is
      # 22304 B/token here, so this holds ~865k tokens (~28 worker contexts);
      # the old 2048 held three, which is why switches always cost a reprefill.
      "--cache-ram" "18432"
      "--slot-prompt-similarity" "0.5"

      "--parallel" "1"
      # The Ryzen's 8 physical cores; SMT measured substantially slower for
      # the CPU-resident MoE experts.
      "--threads" "8"
      "--metrics"
      "--timeout" "0"
    ];
  };

  systemd.services.llama-cpp = {
    # ProtectHome=true also hides $HOME from RADV, which then fails to create
    # its shader cache ("Permission denied---disabling") and recompiles every
    # shader on each start. Point it at the unit's own CacheDirectory.
    environment = {
      HOME = "/var/lib/llama-cpp";
      XDG_CACHE_HOME = "/var/cache/llama-cpp";
    };
    # Module default is 300s. Reloading an 18GB model is slow enough without
    # waiting five minutes first.
    serviceConfig.RestartSec = lib.mkForce 10;
  };

  # Second, tiny instance purely for OpenCode's title/metadata calls.
  #
  # Those are short and frequent, but the 35B has --parallel 1, so every title
  # generation took the single slot and evicted whatever working KV was in it
  # -- a recurring reprefill tax on real work. This moves them off that slot
  # entirely. services.llama-cpp is single-instance, hence the hand-rolled unit;
  # the hardening mirrors what that module applies.
  #
  # CPU-only (-ngl 0): VRAM is fully committed to the 35B, and at 4B/Q4_K_M on
  # CPU a title still returns in well under a second. --threads 2 so it cannot
  # meaningfully steal cores from the 35B's 8 CPU-resident expert threads.
  systemd.services.llama-cpp-small = {
    description = "llama.cpp server (4B) for OpenCode title and metadata calls";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      HOME = "/var/lib/llama-cpp-small";
      XDG_CACHE_HOME = "/var/cache/llama-cpp-small";
    };
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "llama-cpp-small";
      CacheDirectory = "llama-cpp-small";
      ProtectHome = true;
      ProtectSystem = "strict";
      PrivateTmp = true;
      NoNewPrivileges = true;
      Restart = "on-failure";
      RestartSec = 10;
      # Plain string rather than escapeShellArgs: every argument here is a bare
      # token, and this renders the same way the services.llama-cpp module does.
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.llama-cpp-vulkan}/bin/llama-server"
        "--host 127.0.0.1"
        "--port 8081"
        "-m /var/lib/llama-models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf"
        # This model's KV is 144 KiB/token (36 layers, 8 KV heads, f16) -- far
        # heavier per token than the 35B's 22 KiB, because the 35B has only two
        # KV heads and quantised KV. 16384 costs ~2.4GB of RAM; don't raise it
        # casually. Keep in sync with the local-title provider's limit.context.
        "-c 16384"
        "-ngl 0"
        "--threads 2"
        "--parallel 1"
        "--jinja"
        "--metrics"
        "--timeout 0"
        # 2507-Instruct is a non-thinking model, so there is no reasoning
        # budget to spend here and no </think> to strip.
        "--temp 0.2"
      ];
    };
  };

  # The degenerate-loop failure mode was only ever cured by a restart: after
  # long uptime under OpenCode's 7 agents sharing one slot, trivial prompts
  # started returning repeated `</think>` or verbatim echoes, and the very
  # same prompts were fine again immediately after restarting. The other
  # workstation never sees this because its router unloads the model after
  # 300s idle, so it can't accumulate state in the first place. A nightly
  # restart is the cheap equivalent -- the model reloads in ~21s.
  # try-restart is a no-op when the service is already stopped.
  systemd.services.llama-cpp-refresh = {
    description = "Restart llama-cpp to clear accumulated slot/prompt-cache state";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl try-restart llama-cpp.service";
    };
  };

  systemd.timers.llama-cpp-refresh = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "05:00";
      RandomizedDelaySec = "15m";
      # Don't fire a catch-up restart mid-session if the machine was asleep.
      Persistent = false;
    };
  };

  # Model store outside /home, readable by the unit's DynamicUser.
  systemd.tmpfiles.rules = [
    "d /var/lib/llama-models 0755 root root -"
  ];

  services.gnome.gnome-browser-connector.enable = true;

  # Remote desktop over RDP. Enables both the system daemon (Remote Login:
  # headless GDM-managed session, no console login required) and the user
  # daemon (Desktop Sharing: mirrors the active session on seat0).
  services.gnome.gnome-remote-desktop.enable = true;

  # "grdctl --system rdp enable" enables the unit over D-Bus (EnableUnitFiles),
  # which writes to /etc/systemd/system/graphical.target.wants -- a read-only
  # store symlink here, so it always fails on NixOS. Wire the Remote Login
  # daemons into graphical.target declaratively for the same runtime effect.
  systemd.services.gnome-remote-desktop.wantedBy = [ "graphical.target" ];
  systemd.services.gnome-remote-desktop-configuration.wantedBy = [ "graphical.target" ];

  # MANUAL POST-INSTALL STEP -- Remote Login needs state that lives outside the
  # flake, in /var/lib/gnome-remote-desktop. grdctl is the only way to set it,
  # so a fresh install of this config starts with the system daemon running but
  # RDP *disabled*: it binds no port and 3389 silently refuses connections,
  # while Desktop Sharing on 3390 keeps working and hides the problem. Logging
  # out then strands the machine, since 3390 dies with the session it mirrors.
  #
  #   sudo grdctl --system rdp set-credentials <user> <password>
  #   sudo grdctl --system rdp enable
  #   sudo systemctl restart gnome-remote-desktop
  #
  # Verify with "ss -tln | grep 3389" before relying on it. The wantedBy above
  # only starts the daemon; it does not flip the enabled flag these commands do.
  # Both print a benign "Init TPM credentials failed ... using GKeyFile as
  # fallback" warning on hardware without a usable TPM.

  systemd.user.services.custom_xset_service = {
      description = "setting this so that the screen doesnt randomly turn off";
      #serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        xset -dpms
      '';
      wantedBy = [ "multi-user.target" ];
  };

  #   services.flatpak.package = [
  #     "io.github.zen_browser.zen"
  #   ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}

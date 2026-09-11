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
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
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

  services.gnome.gnome-browser-connector.enable = true;
  
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

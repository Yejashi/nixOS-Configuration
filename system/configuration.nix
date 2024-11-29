# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot = {
    # Get latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    initrd.kernelModules = ["amdgpu"];

    loader = {
        grub = {
            enable = true;
            devices = [ "/dev/vda" ];
            useOSProber = true;
            # You can have at most 5 nixos configurations at a time
            configurationLimit = 5;
        };
        timeout = 5;
    };
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

      displayManager = {
	    gdm.enable = true;
      };
      desktopManager = {
        # Enable the GNOME Desktop Environment.
	    gnome.enable = true;
      };
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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

  sound = {
    enable = true;
    mediaKeys.enable = true;
  };

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
    extraGroups = [ "networkmanager" "wheel" "video" "storage" "network" "lp" ];
    initialPassword = "password";
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    curl
    zip
    vim
    git
    sshfs
    python312
    python312Packages.pillow

    # Gnome Packages
    gnome3.gnome-tweaks

    # Icons + Themes
    tela-circle-icon-theme
    orchis-theme
    
    kitty
    xfce.thunar
    vscode
    material-icons
    starship
    input-remapper
    # flatpak
    # flatpak-builder
    # Add zen-browser later on
  ];


  # TODO: Find a way to fix neofetch icons
  fonts.packages = with pkgs; [
    source-code-pro
    noto-fonts
    nerdfonts
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

  
  services.input-remapper.enable = true;

  services.flatpak.enable = true;
  environment.variables.XDG_DATA_DIRS = lib.mkMerge [
    "/var/lib/flatpak/exports/share"
    "~/.local/share/flatpak/exports/share"
  ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}

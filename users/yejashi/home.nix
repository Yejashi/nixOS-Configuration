{ config, pkgs, ... }:

{

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "yejashi";
  home.homeDirectory = "/home/yejashi";


  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    htop
    neofetch
    spotify
    foliate
    variety
    slack
    rofi
    fzf
    # starship
    ranger
    # vimPlugins.vim-plug
    # Gnome Extensions
    gnomeExtensions.blur-my-shell
    gnomeExtensions.bluetooth-battery-meter
    gnomeExtensions.just-perfection
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.user-themes
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".config/ranger" = {
      source = ./ranger;
      recursive = true;
    };

    ".config/rofi" = {
      source = ./rofi;
      recursive = true;
    };

    ".config/neofetch" = {
      source = ./neofetch;
      recursive = true;
    };

    ".config/kitty" = {
      source = ./kitty;
      recursive = true;
    };

    ".config/input-remapper-2" = {
      source = ./input-remapper-2;
      recursive = true;
    };

    # Make firefox look roundy, might i say ride eternal, shiny and chrome
    ".mozilla/firefox/huuecasm.default/chrome" = {
      source = ./chrome;
      recursive = true;
    };

    "Documents/wallpapers/walls" = {
      source = ./walls;
      recursive = true;
    };

    ".mozilla/firefox/huuecasm.default/user.js" = {
      source = ./user.js;
    };

    ".vimrc" = {
      source = ./.vimrc;
    };

    ".bashrc" = {
      source = ./.bashrc;
    };

  };

  dconf.settings = {
    # ...
    "org/gnome/shell" = {
      disable-user-extensions = false;

      # `gnome-extensions list` for a list
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "trayIconsReloaded@selfmade.pl"
        "blur-my-shell@aunetx"
        "Bluetooth-Battery-Meter@maniacx.github.com"
        "just-perfection-desktop@just-perfection"
      ];

      favorite-apps = [
        "firefox.desktop"
        "code.desktop"
        "spotify.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
    };
  };
  # TODO: What to do with this?
#   programs.python = {
#     enable = true;
#     package = pkgs.python312;
#   };
  
  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/yejashi/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
  };

  ## Manage dot files here: store files in github and create symlinks where they are necessary

}

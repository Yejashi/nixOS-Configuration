let
/*
 * What you're seeing here is our nix formatter. It's quite opinionated:
 */
  sample-01 = { lib }:
{
  list = [
    elem1
    elem2
    elem3
  ] ++ lib.optionals stdenv.isDarwin [
    elem4
    elem5
  ]; # and not quite finished
}; # it will preserve your newlines

  sample-02 = { stdenv, lib }:
{
  list =
    [
      elem1
      elem2
      elem3
    ]
    ++ lib.optionals stdenv.isDarwin [ elem4 elem5 ]
    ++ lib.optionals stdenv.isLinux [ elem6 ]
    ;
};
# but it can handle all nix syntax,
# and, in fact, all of nixpkgs in <20s.
# The javascript build is quite a bit slower.
 sample-03 = { stdenv, system }:
assert system == "i686-linux";
stdenv.mkDerivation { };
# these samples are all from https://github.com/nix-community/nix-fmt/tree/master/samples
sample-simple = # Some basic formatting
{
  empty_list = [ ];
  inline_list = [ 1 2 3 ];
  multiline_list = [
    1
    2
    3
    4
  ];
  inline_attrset = { x = "y"; };
  multiline_attrset = {
    a = 3;
    b = 5;
  };
  # some comment over here
  fn = x: x + x;
  relpath = ./hello;
  abspath = /hello;
  # URLs get converted from strings
  url = "https://foobar.com";
  atoms = [ true false null ];
  # Combined
  listOfAttrs = [
    {
      attr1 = 3;
      attr2 = "fff";
    }
    {
      attr1 = 5;
      attr2 = "ggg";
    }
  ];

  # long expression
  attrs = {
    attr1 = short_expr;
    attr2 =
      if true then big_expr else big_expr;
  };
}
;
in
[ sample-01 sample-02 sample-03 ]
  

{
  config,
  pkgs,
  lib,
  ...
}:

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
    htop
    neofetch
    spotify
    foliate
    variety
    slack
    rofi
    fzf
    cpu-x
    # starship
    ranger
    neovim
    zoom-us
    gdu
    obsidian
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
    # ".mozilla/firefox/huuecasm.default/chrome" = {
    #   source = ./chrome;
    #   recursive = true;
    # };

    # ".mozilla/firefox/*.default/user.js" = {
    #   source = ./user.js;
    # };

    "Documents/wallpapers/walls" = {
      source = ./walls;
      recursive = true;
    };

    ".vimrc" = {
      source = ./.vimrc;
    };

    ".bashrc" = {
      source = ./.bashrc;
    };

    ".ssh/config" = {
      source = ./config;
    };

    ".config/variety/variety.conf" = {
      source = ./variety/variety.conf;
    };

  };

  dconf.settings = {
    # ...
    "org/gnome/shell" = {
      disable-user-extensions = false;

      # `gnome-extensions list` for a list
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "Bluetooth-Battery-Meter@maniacx.github.com"
        "trayIconsReloaded@selfmade.pl"
        "just-perfection-desktop@just-perfection"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
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

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      action-middle-click-titlebar = "minimize";
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Orchis-Dark";
    };

    # Remap default key bindings
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-left = [ "<Super>Tab" ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-right = [ "<Super>grave" ];
    };

    # - Disable conflicts
    "org/gnome/desktop/wm/keybindings" = {
      switch-applications = [ ];
    };

    # This might be the incorrect invalidation
    "org/gnome/desktop/wm/keybindings" = {
      switch-applications-backword = [ ];
    };

    # Custom Keybindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Rofi";
      binding = "<Control>p";
      command = "rofi -show drun";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Kitty";
      binding = "<Super>Return";
      command = "kitty --single-instance";
    };
  };

  # Legacy Application Theme
  gtk = {
    enable = true;

    theme = {
      name = "Orchis-Dark";
      package = pkgs.orchis-theme;
    };

    iconTheme = {
      name = "Tela-circle";
      package = pkgs.tela-circle-icon-theme;
    };
  };

  # I should be executed for writing something like this. Forgive me dear observer
  home.activation.postBuildScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "~/home_env" ]; then
        /run/current-system/sw/bin/python -m venv home_env
    fi
  '';

  home.sessionVariables = {
    EDITOR = "vim";
  };

}
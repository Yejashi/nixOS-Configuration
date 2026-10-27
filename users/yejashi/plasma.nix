# KDE Plasma session: Kanagawa Dragon rice (Klassy decorations, Darkly app
# style, Panel Colorizer top bar), Plastile tiling and hyprland-style
# keybindings. Only affects the Plasma session; the
# GNOME settings in home.nix are untouched.
#
# Plastile, the rounded-corners effect, Klassy, Darkly and Panel Colorizer
# are installed system-wide (system/configuration.nix) because KWin, Qt or
# plasmashell load them and they must match the unstable KDE stack; this file
# only turns them on and configures them.
#
# plasma-manager merges into the existing KDE config files rather than
# resetting them, so tweaks made in System Settings survive unless they touch
# a key set here. Log out and back in after `home-manager switch`: KWin and
# kglobalaccel only pick up some of these keys at login.
{ pkgs, inputs, ... }:

let
  wallpaper = ./wallpapers/mellow-dreams.jpg;

  # Kanagawa Dragon, https://github.com/rebelot/kanagawa.nvim
  # (colors.lua: dragonBlack*, dragonWhite, dragonRed, dragonPink)
  kd = {
    base = "#181616"; # dragonBlack3
    overlay = "#282727"; # dragonBlack4
    border = "#393836"; # dragonBlack5
    text = "#c5c9c5"; # dragonWhite
    red = "#c4746e"; # dragonRed, the sakura accent
    pink = "#a292a3"; # dragonPink
  };

  # Panel Colorizer settings. The widget merges this over its own defaults
  # (contents/ui/code/globals.js in the package), so only changed keys are
  # listed. sourceType 0 = custom color.
  custom = color: alpha: {
    enabled = true;
    sourceType = 0;
    custom = color;
    inherit alpha;
  };
  corners = r: {
    enabled = true;
    corner = {
      topLeft = r;
      topRight = r;
      bottomRight = r;
      bottomLeft = r;
    };
  };
  colorizer = {
    # Plasma's own panel background is hidden; Panel Colorizer draws the bar
    # instead: one continuous translucent, blurred, rounded strip.
    nativePanel.background = {
      enabled = true;
      opacity = 0;
      shadow = false;
    };
    # Inset from the top and sides of the (non-floating) panel area, flush
    # with its bottom: Plastile's gapOuter is then the only space between the
    # bar and the windows, and the bar's sides line up with the window edges.
    panel.normal = {
      enabled = true;
      blurBehind = true;
      backgroundColor = custom kd.base 0.9;
      radius = corners 12;
      margin = {
        enabled = true;
        side = {
          top = 6;
          left = 6;
          right = 6;
          bottom = 0;
        };
      };
      border = {
        enabled = true;
        width = 1;
        color = custom kd.border 0.8;
      };
      shadow.background = {
        enabled = true;
        size = 6;
        yOffset = 2;
        color = custom "#000000" 0.45;
      };
    };
    widgets.normal = {
      enabled = true;
      foregroundColor = custom kd.text 1;
      spacing = 6;
    };
    # A hovered widget gets a faint rounded highlight inside the bar.
    widgets.hovered = {
      enabled = true;
      backgroundColor = custom kd.overlay 0.9;
      radius = corners 8;
      margin = {
        enabled = true;
        side = {
          left = 0;
          right = 0;
          top = 3;
          bottom = 3;
        };
      };
    };
    trayWidgets.normal = {
      enabled = true;
      foregroundColor = custom kd.text 1;
    };
  };

  # Plastile command ids are documented in plastile/docs/user/SHORTCUTS.md.
  # Every command that has a default key is set explicitly here, so none of
  # its defaults (Meta+Shift+HJKL, Meta+Ctrl+HJKL, ...) linger and collide
  # with the bindings below.
  plastile = {
    # Focus: Meta+HJKL (hyprland movefocus)
    "plastile.focus.left" = "Meta+H";
    "plastile.focus.down" = "Meta+J";
    "plastile.focus.up" = "Meta+K";
    "plastile.focus.right" = "Meta+L";
    "plastile.focus.next" = "Meta+N";
    "plastile.focus.previous" = "Meta+Shift+N";
    "plastile.focus.output-next" = "Meta+O";

    # Swap: Meta+Shift+HJKL (hyprland movewindow)
    "plastile.swap.left" = "Meta+Shift+H";
    "plastile.swap.down" = "Meta+Shift+J";
    "plastile.swap.up" = "Meta+Shift+K";
    "plastile.swap.right" = "Meta+Shift+L";
    "plastile.swap.master" = "Meta+Shift+Return";

    # Resize: Meta+Ctrl+L / H (hyprland resizeactive), plus Plastile's own keys
    "plastile.resize.grow" = [ "Meta+Ctrl+L" "Meta+Ctrl+=" ];
    "plastile.resize.shrink" = [ "Meta+Ctrl+H" "Meta+Ctrl+-" ];
    "plastile.resize.equalize" = "Meta+Ctrl+E";

    "plastile.master.increase" = "Meta+Shift+I";
    "plastile.master.decrease" = "Meta+Shift+D";

    # Layouts
    "plastile.layout.next" = "Meta+Space";
    "plastile.layout.previous" = "Meta+Ctrl+Space";
    "plastile.layout.master-stack" = "Meta+Shift+T";
    "plastile.layout.bsp" = "Meta+Shift+B";
    "plastile.layout.monocle" = "Meta+M";
    "plastile.layout.rotate-clockwise" = "Meta+S"; # hyprland togglesplit

    # Windows
    "plastile.window.toggle-float" = "Meta+Shift+Space"; # hyprland togglefloating
    "plastile.move.output-next" = "Meta+Shift+O";

    # Runtime / diagnostics
    "plastile.runtime.toggle-suspend" = "Meta+Ctrl+S";
    "plastile.runtime.reload-config" = "Meta+Ctrl+R";
    "plastile.inspect.explain-window" = "Meta+Ctrl+I";
  };

  desktops = [ 1 2 3 4 5 ];
  # Meta+Shift+<digit> arrives as the shifted symbol on a US layout.
  shiftedDigit = {
    "1" = "!";
    "2" = "@";
    "3" = "#";
    "4" = "$";
    "5" = "%";
  };
in
{
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  home.packages = with pkgs; [
    inter
  ];

  xdg.dataFile."color-schemes/KanagawaDragon.colors".source = ./plasma/KanagawaDragon.colors;

  programs.plasma = {
    enable = true;

    workspace = {
      # No global look-and-feel package: each part is set on its own so none
      # of them gets overridden by a theme's defaults.
      colorScheme = "KanagawaDragon";
      theme = "default"; # Plasma Style: Breeze, which follows the color scheme
      widgetStyle = "Darkly";
      windowDecorations = {
        library = "org.kde.klassy";
        theme = "Klassy";
      };
      iconTheme = "Tela-circle-dark"; # system package (configuration.nix)
      cursor = {
        theme = "breeze_cursors"; # Plasma's default cursor
        size = 24;
      };
      splashScreen.theme = "None";
      wallpaper = "${wallpaper}";
    };

    fonts = {
      general = {
        family = "Inter";
        pointSize = 10;
      };
      small = {
        family = "Inter";
        pointSize = 8;
      };
      toolbar = {
        family = "Inter";
        pointSize = 10;
      };
      menu = {
        family = "Inter";
        pointSize = 10;
      };
      windowTitle = {
        family = "Inter";
        pointSize = 10;
        weight = "demiBold";
      };
      fixedWidth = {
        family = "FiraCode Nerd Font Mono";
        pointSize = 10;
      };
    };

    kscreenlocker.appearance.wallpaper = "${wallpaper}";

    # One floating top bar, drawn by Panel Colorizer:
    # launcher desktops  pinned apps  ...  clock  ...  tray
    panels = [
      {
        location = "top";
        # Pinned: left unset, Plasma creates the panel on whichever monitor
        # is active when the script runs. 0 is the primary (HDMI-A-1).
        screen = 0;
        height = 40; # 6px gap above (colorizer margin) + 34px bar
        # Not floating: Plasma's floating gap sits outside the colorizer's
        # background, so the drawn bar touched the screen edge anyway.
        floating = false;
        widgets = [
          {
            kickoff = {
              icon = "nix-snowflake-white";
              sortAlphabetically = true;
            };
          }
          {
            # Without showOnlyCurrentScreen each desktop is drawn at the
            # combined 5120x1440 size of both monitors: a long strip of blocks.
            pager.general = {
              showOnlyCurrentScreen = true;
              showWindowOutlines = false;
              displayedText = "desktopNumber";
            };
          }
          {
            panelSpacer = {
              expanding = false;
              length = 6;
            };
          }
          {
            iconTasks = {
              launchers = [
                "applications:firefox.desktop"
                "applications:code.desktop"
                "applications:spotify.desktop"
                "applications:org.kde.dolphin.desktop"
                "applications:kitty.desktop"
              ];
              appearance = {
                showTooltips = true;
                highlightWindows = true;
                indicateAudioStreams = true;
              };
            };
          }
          { panelSpacer.expanding = true; }
          {
            digitalClock = {
              date = {
                enable = true;
                format.custom = "ddd d MMM";
                position = "besideTime";
              };
              time.format = "12h";
              font = {
                family = "Inter";
                weight = 600;
                size = 10;
              };
            };
          }
          { panelSpacer.expanding = true; }
          "org.kde.plasma.systemtray"
          {
            name = "luisbocanegra.panel.colorizer";
            config.General = {
              isEnabled = true;
              hideWidget = true;
              islandsEnabled = false;
              globalSettings = builtins.toJSON colorizer;
            };
          }
        ];
      }
    ];

    kwin = {
      virtualDesktops = {
        number = builtins.length desktops;
        rows = 1;
      };
      titlebarButtons = {
        left = [ ];
        right = [
          "minimize"
          "maximize"
          "close"
        ];
      };
      borderlessMaximizedWindows = true;
      effects = {
        blur = {
          enable = true;
          strength = 8;
          noiseStrength = 4;
        };
        translucency.enable = true;
        windowOpenClose.animation = "scale";
        desktopSwitching.animation = "slide";
        dimInactive.enable = false;
      };
    };

    # Klassy window decoration: plain line-style minimize/maximize/close
    # icons in the title text color (close turns red on hover), rounded
    # hover backgrounds, left-aligned bold title, no separator
    # line, titlebar blended into the window header. Enum values are the
    # choice names from klassy-decoration.kcfg.
    configFile."klassy/klassyrc" = {
      Windeco = {
        ButtonIconStyle = "StyleKite";
        ButtonShape = "ShapeIntegratedRoundedRectangle";
        IconSize = "IconMedium";
        WindowCornerRadius = 12;
        DrawTitleBarSeparator = false;
        DrawBorderOnMaximizedWindows = false;
        BoldTitle = true;
        ColorizeWindowOutlineWithButton = false;
      };
      ButtonColors = {
        ButtonIconColorsActive = "TitleBarTextNegativeClose";
        ButtonIconColorsInactive = "TitleBarText";
      };
      TitleBarSpacing = {
        TitleAlignment = "AlignLeft";
        TitleBarTopMargin = 4;
        TitleBarBottomMargin = 4;
      };
      TitleBarOpacity = {
        ActiveTitleBarOpacity = 92;
        InactiveTitleBarOpacity = 85;
        OpaqueMaximizedTitleBars = true;
        BlurTransparentTitleBars = true;
        ApplyOpacityToHeader = true;
      };
      ShadowStyle = {
        ShadowSizeActive = "ShadowLarge";
        ShadowSizeInactive = "ShadowSmall";
        ShadowStrengthActive = 200;
        ShadowStrengthInactive = 90;
      };
    };

    # Baloo file indexing off: it crawled the whole home dir, held ~11 GB of
    # RAM and wrote hundreds of GB to the NVMe per hour.
    configFile.baloofilerc."Basic Settings"."Indexing-Enabled" = false;

    configFile.kwinrc = {
      # Each monitor keeps its own current desktop; a desktop switch only
      # changes the active monitor (the one holding the focused window or
      # the pointer). New in KWin 6.7; the System Settings checkbox
      # "Switch desktops independently for each screen" writes the same key.
      Windows.PerOutputVirtualDesktops = true;

      Plugins = {
        # Plastile tiling + its window motion effect (both from the plastile package)
        plastileEnabled = true;
        plastile_motionEnabled = true;
        # kde-rounded-corners
        kwin4_effect_shapecornersEnabled = true;
      };

      # Thin frame; Klassy and the outline below do the visual work.
      "org.kde.kdecoration2".BorderSize = "Tiny";
      "org.kde.kdecoration2".BorderSizeAuto = false;

      # kde-rounded-corners: round every window and give the focused one a
      # dragonRed -> dragonPink gradient outline. Off for maximized/fullscreen windows.
      Round-Corners = {
        Size = 12;
        InactiveCornerRadius = 12;
        OutlineThickness = 2;
        ActiveOutlineUseCustom = true;
        ActiveOutlineUsePalette = false;
        OutlineColor = kd.red;
        OutlineIsGradient = true;
        OutlineColor2 = kd.pink;
        OutlineGradientAngle = 45;
        InactiveOutlineThickness = 1;
        InactiveOutlineUseCustom = true;
        InactiveOutlineUsePalette = false;
        InactiveOutlineColor = kd.overlay;
        DisableRoundMaximize = true;
        DisableOutlineMaximize = true;
        DisableRoundFullScreen = true;
        DisableOutlineFullScreen = true;
      };

      "Script-plastile" = {
        layout = "master-stack";
        gapInner = 8;
        gapOuter = 6; # matches the bar's side inset
        masterRatio = 0.55;
      };
    };

    # GNOME keeps the session unlocked so Desktop Sharing can attach; match it.
    kscreenlocker = {
      autoLock = false;
      lockOnResume = true;
    };

    hotkeys.commands = {
      kitty = {
        name = "Kitty";
        key = "Meta+Return";
        command = "kitty --single-instance";
      };
      walker = {
        name = "Walker";
        key = "Ctrl+P";
        command = "walker";
      };
    };

    shortcuts = {
      kwin =
        plastile
        // {
          "Window Close" = "Meta+Shift+Q";
          "Window Fullscreen" = "Meta+F";

          # GNOME carry-overs: Meta+Tab / Meta+` move between desktops
          "Switch to Previous Desktop" = "Meta+Tab";
          "Switch to Next Desktop" = "Meta+`";
          "Walk Through Windows" = "Alt+Tab";
          "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
          "Walk Through Windows of Current Application" = "Alt+`";
          "Walk Through Windows of Current Application (Reverse)" = "Alt+~";
        }
        // builtins.listToAttrs (
          builtins.concatMap (n: [
            {
              name = "Switch to Desktop ${toString n}";
              value = "Meta+${toString n}";
            }
            {
              name = "Window to Desktop ${toString n}";
              value = "Meta+${shiftedDigit.${toString n}}";
            }
          ]) desktops
        );

      # Meta+1..9 belong to the desktops above, not the task manager.
      plasmashell = builtins.listToAttrs (
        map (n: {
          name = "activate task manager entry ${toString n}";
          value = [ ];
        }) [ 1 2 3 4 5 6 7 8 9 ]
      );

      ksmserver = {
        # Meta+L is Plastile's focus-right now; lock moves to the hyprland key.
        "Lock Session" = [
          "Ctrl+Alt+L"
          "Screensaver"
        ];
        "Log Out" = [
          "Meta+Escape"
          "Ctrl+Alt+Del"
        ];
      };
    };
  };
}

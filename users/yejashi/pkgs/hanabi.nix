{ lib
, buildNpmPackage
, meson
, ninja
, gettext
, glib
, bash
, gjs
, gtk4
, gobject-introspection
, wrapGAppsHook4
, gst_all_1
, src
}:

let
  uuid = "hanabi-extension@jeffshee.github.io";
in
buildNpmPackage rec {
  pname = "gnome-ext-hanabi";
  version = "unstable";

  inherit src;

  npmDepsHash = "sha256-uYhpa0MdWgkvX9XRk6lHR3ShoDtTKfrP9ZFsIxv34X8=";
  dontNpmBuild = true;

  nativeBuildInputs = [
    meson
    ninja
    gettext
    glib
    bash
    gobject-introspection
    wrapGAppsHook4
  ];

  buildInputs = [
    gjs
    gtk4
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
  ];

  # We build the gjs wrapper by hand in postInstall; there is nothing else in
  # $out/bin for the hook to pick up.
  dontWrapGApps = true;

  postPatch = ''
    substituteInPlace build-aux/meson-postinstall.sh \
      --replace '#!/bin/bash' '#!${bash}/bin/bash'
  '';

  preConfigure = ''
    npm run build
  '';

  # meson was already configured with --prefix=$out by the setup hook, so
  # passing --destdir $out again nests the whole tree under $out/nix/store/...
  # and nothing lands where GNOME Shell looks for it.
  installPhase = ''
    runHook preInstall
    meson install
    runHook postInstall
  '';

  postInstall = ''
    # The extension spawns plain `gjs` from PATH to run the renderer. The GNOME
    # session ships neither the gjs binary nor the GTK4/GStreamer typelibs and
    # decoders it needs, so point it at a wrapper that carries its own env.
    substituteInPlace $out/share/gnome-shell/extensions/${uuid}/extension.js \
      --replace-fail 'argv.push("gjs", "-m"' "argv.push(\"$out/bin/hanabi-gjs\", \"-m\""

    # GNOME Shell reads an extension's settings from a compiled schema inside
    # the extension directory; upstream only installs the XML to the datadir.
    install -Dm644 $out/share/glib-2.0/schemas/*.gschema.xml \
      -t $out/share/gnome-shell/extensions/${uuid}/schemas
    glib-compile-schemas $out/share/gnome-shell/extensions/${uuid}/schemas
  '';

  # gappsWrapperArgs is only filled in during fixup, so the wrapper has to be
  # built after it rather than in postInstall.
  postFixup = ''
    makeWrapper ${gjs}/bin/gjs $out/bin/hanabi-gjs "''${gappsWrapperArgs[@]}"
  '';

  meta = with lib; {
    description = "Hanabi GNOME Shell extension";
    platforms = platforms.linux;
  };
}

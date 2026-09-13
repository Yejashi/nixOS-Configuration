{ lib
, buildNpmPackage
, meson
, ninja
, gettext
, glib
, bash
, src
}:

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
  ];

  postPatch = ''
    substituteInPlace build-aux/meson-postinstall.sh \
      --replace '#!/bin/bash' '#!${bash}/bin/bash'
  '';

  preConfigure = ''
    npm run build
  '';

  installPhase = ''
    meson install --destdir $out
  '';

  meta = with lib; {
    description = "Hanabi GNOME Shell extension";
    platforms = platforms.linux;
  };
}

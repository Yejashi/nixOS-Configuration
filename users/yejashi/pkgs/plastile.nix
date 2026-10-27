# Plastile: tiling for KDE Plasma 6 as a KWin script (github:Yejashi/plastile).
# Ships three things under one prefix:
#   share/kwin/scripts/plastile        the KWin script (enabled via kwinrc [Plugins])
#   share/kwin/effects/plastile_motion the optional motion effect (off until enabled)
#   libexec/plastile-state + share/dbus-1/services/org.kde.plastile.State.service
#                                      the persistence helper, D-Bus activated
# Needs KWin >= 6.7 (X-Plasma-API-Minimum-Version), hence Plasma from unstable.
{
  lib,
  stdenv,
  buildNpmPackage,
  nodejs_26,
  cmake,
  kdePackages,
  src,
}:

let
  helper = stdenv.mkDerivation {
    pname = "plastile-state";
    version = "0.1.0";
    src = "${src}/helper";
    nativeBuildInputs = [ cmake ];
    buildInputs = [ kdePackages.qtbase ];
    # Console Qt Core/DBus program: no platform plugins to wrap in.
    dontWrapQtApps = true;
  };
in
buildNpmPackage {
  pname = "plastile";
  version = "0.1.0";
  inherit src;

  nodejs = nodejs_26;
  npmDepsHash = "sha256-wB64iPzOcPPp+y3e7luDmTI4Twxiv9kQy7801937fww=";

  # `npm run build` writes package/contents/code/plastile.mjs.
  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall
    test -f package/contents/code/plastile.mjs
    mkdir -p $out/share/kwin/scripts $out/share/kwin/effects
    cp -r package $out/share/kwin/scripts/plastile
    cp -r effect $out/share/kwin/effects/plastile_motion
    cp -r ${helper}/. $out/
    runHook postInstall
  '';

  passthru = { inherit helper; };

  meta = {
    description = "Fast, predictable tiling layer for KDE Plasma 6 that keeps KWin";
    homepage = "https://github.com/Yejashi/plastile";
    platforms = lib.platforms.linux;
  };
}

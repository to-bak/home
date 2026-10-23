{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "reveal-js";
  version = "6.0.2";

  # The official npm release includes the compiled distribution and plugins.
  # Installing those assets needs neither npm dependencies nor a Node runtime.
  src = fetchurl {
    url = "https://registry.npmjs.org/reveal.js/-/reveal.js-${version}.tgz";
    hash = "sha256-Lwwgv7AkR6GYoevoqMCXpUN9A1yqOPKCC/S6iHo+rJE=";
  };

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/reveal.js"
    cp -r dist css LICENSE README.md package.json "$out/share/reveal.js/"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    for asset in dist/reveal.js dist/reveal.css dist/theme/black.css \
      dist/plugin/notes.js dist/plugin/zoom.js dist/plugin/search.js \
      css/theme/fonts/source-sans-pro/source-sans-pro.css; do
      test -s "$out/share/reveal.js/$asset"
    done
    runHook postInstallCheck
  '';

  meta = {
    description =
      "HTML presentation framework: browser assets, themes and plugins";
    homepage = "https://revealjs.com";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}

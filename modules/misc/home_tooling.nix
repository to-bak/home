{ config, pkgs-unstable, extendedLib, ... }:

with extendedLib;
let
  cfg = config.modules.misc.home_tooling;

  # Nixpkgs' codex-acp is the retired Rust adapter and currently embeds an
  # older Codex.  Package the maintained adapter and make it use the exact
  # same Codex derivation as the terminal CLI.
  codex-acp = pkgs-unstable.buildNpmPackage rec {
    pname = "codex-acp";
    version = "1.10.0";

    src = pkgs-unstable.fetchFromGitHub {
      owner = "agentclientprotocol";
      repo = "codex-acp";
      tag = "v${version}";
      hash = "sha256-D8uYd30NRXQYUSBFCi66Oq0iRZXpl8P7nWv2m3+KBig=";
    };

    npmDepsHash = "sha256-df1/kPiZFBEq9Um26Qbo9XaYj2J8BOXQmunCQWquDTo=";
    npmBuildScript = "build";

    nativeBuildInputs = [ pkgs-unstable.makeWrapper ];

    postInstall = ''
      wrapProgram "$out/bin/codex-acp" \
        --set CODEX_PATH "${pkgs-unstable.codex}/bin/codex"
    '';

    meta = {
      description = "ACP adapter for the OpenAI Codex CLI";
      homepage = "https://github.com/agentclientprotocol/codex-acp";
      license = pkgs-unstable.lib.licenses.asl20;
      mainProgram = "codex-acp";
    };
  };
in
{
  options.modules.misc.home_tooling = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs-unstable.codex
      codex-acp
    ];
  };
}

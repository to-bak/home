{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.terminal.tmux;
in
{
  options.modules.misc.terminal.tmux = {
    enable = mkBoolOpt false;
    sessionizer = {
      shallowDirs = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Directories that become a single session (depth=0).";
      };
      deepDirs = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Directories whose subdirs also become sessions (depth=1).";
      };
      agentCommands = mkOption {
        type = with types; listOf str;
        default = [ "claude" "copilot" "agy" ];
        description = "Process names to identify as AI agent panes.";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      sensibleOnTop = false;
      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = sensible;
          # Apply native settings before plugins, so their bindings take effect.
          extraConfig = "source-file ~/.config/tmux/tmux.conf.native";
        }
        resurrect
        onedark-theme
        yank
      ];
    };

    home.packages = [ pkgs.tmuxinator ];

    home.file = {
      ".config/tmux" = {
        source = ../../../configs/tmux;
          recursive = true;
      };
      ".config/tmuxinator" = {
        source = ../../../configs/tmuxinator;
        recursive = true;
      };
      ".config/sessionizer/config".text = ''
        DIRS_SHALLOW=(
        ${builtins.concatStringsSep "\n" (map (d: "  \"${d}\"") cfg.sessionizer.shallowDirs)}
        )
        DIRS_DEEP=(
        ${builtins.concatStringsSep "\n" (map (d: "  \"${d}\"") cfg.sessionizer.deepDirs)}
        )
        AGENT_COMMANDS=(
        ${builtins.concatStringsSep "\n" (map (d: "  \"${d}\"") cfg.sessionizer.agentCommands)}
        )
      '';
    };
  };	
}

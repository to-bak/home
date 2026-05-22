{ config, pkgs, pkgs-stable, pkgs-sesh, extendedLib, nixGL, ... }:

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
        default = [ "claude" "copilot" ];
        description = "Process names to identify as AI agent panes.";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.sensible
	tmuxPlugins.resurrect
	tmuxPlugins.onedark-theme
	tmuxPlugins.yank
      ];

       extraConfig = ''
	source-file ~/.config/tmux/tmux.conf.native
	run-shell ${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible/sensible.tmux
	run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
	run-shell ${pkgs.tmuxPlugins.onedark-theme}/share/tmux-plugins/onedark-theme/tmux-onedark-theme.tmux
	run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux
       '';
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

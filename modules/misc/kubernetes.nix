{ config, pkgs, pkgs-kubelogin, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.kubernetes;

   # k9s calls Go's os/user.Current() → getpwuid_r(), which fails when the
   # user is managed by AD/LDAP and nix's glibc can't reach the system NSS
   # modules. Wrap k9s with libnss_wrapper, feeding it a passwd/group file
   # built at runtime from the system's getent.
   k9s-wrapped = pkgs.writeShellScriptBin "k9s" ''
     TMPPASSWD=$(mktemp)
     TMPGROUP=$(mktemp)
     trap 'rm -f "$TMPPASSWD" "$TMPGROUP"' EXIT

     getent passwd "$(id -u)" > "$TMPPASSWD"
     getent group  "$(id -g)" > "$TMPGROUP"

     export NSS_WRAPPER_PASSWD="$TMPPASSWD"
     export NSS_WRAPPER_GROUP="$TMPGROUP"
     export LD_PRELOAD="${pkgs.nss_wrapper}/lib/libnss_wrapper.so"

     exec ${pkgs.k9s}/bin/k9s "$@"
   '';
in
{
  options.modules.misc.kubernetes = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.kind
      pkgs.ctlptl
      pkgs.tilt
      pkgs.kubectl
      pkgs.kubectx
      pkgs.kubernetes-helm
      pkgs.azure-cli
      k9s-wrapped
      pkgs-kubelogin.kubelogin
    ];
  };
}

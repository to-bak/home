(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(connection-local-criteria-alist
   '(((:application eshell)
      eshell-connection-default-profile)
     ((:application tramp)
      tramp-connection-local-default-system-profile tramp-connection-local-default-shell-profile)))
 '(connection-local-profile-alist
   '((eshell-connection-default-profile
      (eshell-path-env-list))
     (tramp-connection-local-darwin-ps-profile
      (tramp-process-attributes-ps-args "-acxww" "-o" "pid,uid,user,gid,comm=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" "-o" "state=abcde" "-o" "ppid,pgid,sess,tty,tpgid,minflt,majflt,time,pri,nice,vsz,rss,etime,pcpu,pmem,args")
      (tramp-process-attributes-ps-format
       (pid . number)
       (euid . number)
       (user . string)
       (egid . number)
       (comm . 52)
       (state . 5)
       (ppid . number)
       (pgrp . number)
       (sess . number)
       (ttname . string)
       (tpgid . number)
       (minflt . number)
       (majflt . number)
       (time . tramp-ps-time)
       (pri . number)
       (nice . number)
       (vsize . number)
       (rss . number)
       (etime . tramp-ps-time)
       (pcpu . number)
       (pmem . number)
       (args)))
     (tramp-connection-local-busybox-ps-profile
      (tramp-process-attributes-ps-args "-o" "pid,user,group,comm=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" "-o" "stat=abcde" "-o" "ppid,pgid,tty,time,nice,etime,args")
      (tramp-process-attributes-ps-format
       (pid . number)
       (user . string)
       (group . string)
       (comm . 52)
       (state . 5)
       (ppid . number)
       (pgrp . number)
       (ttname . string)
       (time . tramp-ps-time)
       (nice . number)
       (etime . tramp-ps-time)
       (args)))
     (tramp-connection-local-bsd-ps-profile
      (tramp-process-attributes-ps-args "-acxww" "-o" "pid,euid,user,egid,egroup,comm=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" "-o" "state,ppid,pgid,sid,tty,tpgid,minflt,majflt,time,pri,nice,vsz,rss,etimes,pcpu,pmem,args")
      (tramp-process-attributes-ps-format
       (pid . number)
       (euid . number)
       (user . string)
       (egid . number)
       (group . string)
       (comm . 52)
       (state . string)
       (ppid . number)
       (pgrp . number)
       (sess . number)
       (ttname . string)
       (tpgid . number)
       (minflt . number)
       (majflt . number)
       (time . tramp-ps-time)
       (pri . number)
       (nice . number)
       (vsize . number)
       (rss . number)
       (etime . number)
       (pcpu . number)
       (pmem . number)
       (args)))
     (tramp-connection-local-default-shell-profile
      (shell-file-name . "/bin/sh")
      (shell-command-switch . "-c"))
     (tramp-connection-local-default-system-profile
      (path-separator . ":")
      (null-device . "/dev/null"))))
 '(custom-safe-themes
   '("bf948e3f55a8cd1f420373410911d0a50be5a04a8886cabe8d8e471ad8fdba8e" "3770d0ae70172461ee0a02edcff71b7d480dc54066e8960d8de9367d12171efb" "02f57ef0a20b7f61adce51445b68b2a7e832648ce2e7efb19d217b6454c1b644" default))
 '(org-agenda-files nil)
 '(package-selected-packages
   '(org-download eno vertico which-key nerd-icons erlang format-sql sqlformat magit-delta rust-mode cape envrc git-gutter-fringe git-gutter lsp-ui plan9-theme undo-hl vundo evil-visualstar perspective deft org-roam org-superstar visual-fill-column doom-modeline minions dired-rainbow all-the-icons-dired dmenu json-mode protobuf-mode yaml-mode nix-mode corfu openwith lua-mode wgrep embark-consult 0x0 org-fancy-priorities org-autolist org-bullets evil-org lsp-mode elm-mode haskell-mode elixir-mode evil-collection evil pdf-tools auctex rainbow-delimiters forge magit direnv embark-collect embark marginalia orderless consult-project-extra dired-single sudo-edit vertico-posframe dired-posframe which-key-posframe ivy-posframe posframe powerline doom-themes vterm)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-document-title ((t (:inherit default :weight bold :foreground "unspecified-fg" :height 2.0 :underline nil))))
 '(org-level-1 ((t (:inherit default :weight bold :foreground "unspecified-fg" :height 1.75))))
 '(org-level-2 ((t (:inherit default :weight bold :foreground "unspecified-fg" :height 1.5))))
 '(org-level-3 ((t (:inherit default :weight bold :foreground "unspecified-fg" :height 1.25))))
 '(org-level-4 ((t (:inherit default :weight bold :foreground "unspecified-fg" :height 1.1))))
 '(org-level-5 ((t (:inherit default :weight bold :foreground "unspecified-fg"))))
 '(org-level-6 ((t (:inherit default :weight bold :foreground "unspecified-fg"))))
 '(org-level-7 ((t (:inherit default :weight bold :foreground "unspecified-fg"))))
 '(org-level-8 ((t (:inherit default :weight bold :foreground "unspecified-fg")))))

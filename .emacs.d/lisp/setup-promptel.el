;;; setup-promptel.el --- Org workspace prompt composition -*- lexical-binding: t; -*-

(use-package prompt-compose
  :straight nil
  :load-path "~/git/promptel"
  :demand t)

(use-package org-workspaces
  :straight nil
  :load-path (lambda () (expand-file-name "plugins/" user-emacs-directory))
  :demand t
  :init
  (setq org-workspaces-root-directory "~/.workspaces/org-workspaces/"
        org-workspaces-files (list host/org-roam-path "~/notes/work/workspaces.org"))
  :config
  ;; Keep C-c m for Cockpit; Org workspace commands live under the Org prefix.
  (keymap-set obp/org-prefix-map "w" org-workspaces-map)
  (keymap-set org-workspaces-map "P" #'prompt-compose-menu)
  (require 'org-workspaces-promptel)
  (setq org-workspaces-promptel-extra-context-ids
        '("a8a767a1-1644-4c4a-a05f-23f7b3eab5bf"))
  (require 'promptel-agent-shell)
  (require 'org-workspaces-agent-shell)
  (org-workspaces-agenda-install))

;;; setup-promptel.el ends here

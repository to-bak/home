;;; setup-coding.el --- Development environment and tools -*- lexical-binding: t; -*-

;; Install everywhere; initialize the shell PATH only in graphical sessions.
(use-package exec-path-from-shell
  :commands exec-path-from-shell-initialize
  :init
  (when (memq window-system '(mac ns x pgtk))
    (exec-path-from-shell-initialize)))

(use-package envrc
  :demand t
  :config
  (envrc-global-mode 1))

(use-package dumb-jump
  :commands dumb-jump-xref-activate
  :init
  ;; Keep this behind language-specific xref backends.
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate 90)
  (setq dumb-jump-prefer-searcher 'rg
        dumb-jump-rg-search-args "--pcre2 --no-ignore -g '!_build/'"))

(use-package docker
  :commands docker)

;;; setup-coding.el ends here

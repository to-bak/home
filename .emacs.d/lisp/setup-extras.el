;;; setup-extras.el --- Links, documentation and external files -*- lexical-binding: t; -*-

(use-package sudo-edit
  :commands (sudo-edit sudo-edit-find-file))

(use-package hyperbole
  :demand t
  :bind ("C-c h" . action-key)
  :config
  (hyperbole-mode 1)
  (host/setup-hyperbole-links))

;; Preserve the vendored Info+ library, loading it only with the Info reader.
(use-package info+
  :straight nil
  :load-path "lisp/custom"
  :after info
  :demand t)

(use-package openwith
  :demand t
  :init
  (setq openwith-associations '(("\\.pdf\\'" "zathura" (file))))
  :config
  ;; Keep normal Emacs PDF handling on hosts without the external viewer.
  (when (executable-find "zathura")
    (openwith-mode 1)))

;;; setup-extras.el ends here

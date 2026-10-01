;;; setup-editing.el --- Key hints and editing helpers -*- lexical-binding: t; -*-

;; Preserve the old cleanup-on-save behavior.
(add-hook 'before-save-hook #'whitespace-cleanup)

(use-package which-key
  :straight nil
  :demand t
  :init
  (setq which-key-idle-delay 1)
  :config
  (which-key-mode 1))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Edit exported Consult grep results with C-c C-p, then apply with C-c C-c.
(use-package wgrep)

;;; setup-editing.el ends here

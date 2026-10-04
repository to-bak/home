;;; setup-popper.el --- Popup buffer access -*- lexical-binding: t; -*-

(use-package popper
  :demand t
  :bind (("C-`" . popper-toggle)
         ("M-`" . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  ;; Window placement belongs to setup-windows.el; Popper manages popup access.
  (setq popper-display-control nil
        popper-group-function #'popper-group-by-project
        popper-reference-buffers
        '("\\`\\*Messages\\*\\'"
          "\\`\\*Warnings\\*\\'"
          "\\`\\*Compile-Log\\*\\'"
          "\\`\\*Backtrace\\*\\'"
          "\\`\\*Async Shell Command\\*\\'"
          "Output\\*\\'"
          help-mode
          compilation-mode
          grep-mode))
  :config
  (require 'popper-echo)
  (popper-mode 1)
  (popper-echo-mode 1))

;;; setup-popper.el ends here

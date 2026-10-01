;;; setup-appearance.el --- Text display and focused writing -*- lexical-binding: t; -*-

;; Face defaults also apply to new frames, including daemon client frames.
(set-face-attribute 'default nil :height 130)
(column-number-mode 1)

;; Preserve the native modeline and restore the graphical indicator strips.
(require 'fringe)
(set-fringe-mode 10)

;; Restore visual line numbering, which counts wrapped screen lines.
(setq display-line-numbers-type 'visual)
(setq-default display-line-numbers 'visual)
(global-display-line-numbers-mode 1)

(defun obp/hide-line-numbers ()
  "Hide line numbers in terminal and shell buffers."
  (display-line-numbers-mode 0))

(dolist (hook '(term-mode-hook shell-mode-hook vterm-mode-hook
                treemacs-mode-hook eshell-mode-hook ghostel-mode-hook))
  (add-hook hook #'obp/hide-line-numbers))

;; Center text on demand with M-x olivetti-mode.
(use-package olivetti
  :commands olivetti-mode)

;; Make icons available to packages that use them; activation is separate.
(use-package nerd-icons)

(use-package nerd-icons-completion
  :after marginalia
  :demand t
  :config
  (nerd-icons-completion-marginalia-setup)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;;; setup-appearance.el ends here

;;; setup-vertico.el --- Minibuffer completion display -*- lexical-binding: t; -*-

(use-package vertico
  :demand t
  :init
  (setq vertico-cycle t)
  :config
  (vertico-mode 1))

;; This extension ships with Vertico, so Straight must not install it separately.
(use-package vertico-directory
  :straight nil
  :demand t
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;;; setup-vertico.el ends here

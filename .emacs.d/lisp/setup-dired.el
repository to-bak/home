;;; setup-dired.el --- Directory browsing -*- lexical-binding: t; -*-

(use-package dired
  :straight nil
  :bind (("C-x C-j" . dired-jump)
         :map dired-mode-map
         ("," . dired-up-directory)
         ("." . dired-find-file))
  :hook (dired-mode . hl-line-mode)
  :init
  ;; Restore the GNU ls layout and reuse buffers when entering directories.
  (setq dired-listing-switches "-agho --group-directories-first"
        dired-kill-when-opening-new-dired-buffer t)
  (put 'dired-find-alternate-file 'disabled nil)
  :config
  ;; Leave global Consult search available in Dired.
  (keymap-unset dired-mode-map "M-s g"))

;;; setup-dired.el ends here

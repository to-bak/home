;;; setup-switchy-window.el --- Switch among recent windows -*- lexical-binding: t; -*-

(use-package switchy-window
  ;; GNU ELPA's Git mirror; the local catalog predates this package.
  :straight (:type git :host github :repo "emacs-straight/switchy-window")
  :demand t
  :bind (("M-o" . switchy-window)
         :map other-window-repeat-map
         ("o" . switchy-window))
  :init
  (setq switchy-window-delay 0.75)
  :config
  (switchy-window-minor-mode 1)
  (put 'switchy-window 'repeat-map 'other-window-repeat-map))

;;; setup-switchy-window.el ends here

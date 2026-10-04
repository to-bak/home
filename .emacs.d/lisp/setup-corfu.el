;;; setup-corfu.el --- Completion popup and fallback sources -*- lexical-binding: t; -*-

(use-package cape
  :demand t
  :config
  ;; Mode-specific completion runs first; these are the global fallbacks.
  (add-hook 'completion-at-point-functions #'cape-file 90)
  (add-hook 'completion-at-point-functions #'cape-dabbrev 95))

(use-package corfu
  :demand t
  :bind (:map corfu-map
         ("C-j" . corfu-next)
         ("C-k" . corfu-previous)
         ("TAB" . corfu-insert)
         ("<tab>" . corfu-insert)
         ("C-g" . corfu-quit))
  :init
  (setq corfu-auto t
        corfu-auto-delay 0.2
        corfu-auto-prefix 3
        corfu-preselect 'first
        corfu-preview-current nil
        global-corfu-minibuffer nil)
  :config
  ;; Dismiss the popup before Evil's Insert-state C-g exits to Normal.
  (with-eval-after-load 'evil
    (evil-define-key '(insert replace) corfu-map (kbd "C-g") #'corfu-quit))
  (global-corfu-mode 1))

;;; setup-corfu.el ends here

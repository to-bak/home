;;; terminal-config.el --- Personal terminal settings -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; Terminals
;; ---------------------------------------------------------------------
(defvar-local ghostel-popup-p nil
  "Buffer-local variable to flag and track ghostel popup buffers.")

(defun ghostel-project-toggle ()
  "Toggle the `ghostel-project` terminal window Doom-style."
  (interactive)
  (require 'cl-lib)
  (let ((ghostel-win (cl-find-if (lambda (w)
                                   (buffer-local-value 'ghostel-popup-p (window-buffer w)))
                                 (window-list))))
    (if ghostel-win
        (delete-window ghostel-win)

      (let ((buf (save-window-excursion
                   (ghostel-project)
                   (current-buffer))))
        (when (buffer-live-p buf)
          (with-current-buffer buf
            (setq-local ghostel-popup-p t)
            (setq-local popper-popup-status 'popup))
          (pop-to-buffer buf '(display-buffer-at-bottom (window-height . 0.5))))))))

(use-package ghostel
  :straight t
  :commands (ghostel ghostel-project)
  :bind (("C-c v" . ghostel-project-toggle)
         ("C-c V" . ghostel))
  :init
  (setq ghostel-shell (executable-find "fish")))

;; (use-package vterm
;;   :straight nil
;;   :commands vterm
;;   :config
;;   (setq vterm-max-scrollback 10000
;;         vterm-kill-buffer-on-exit t))
;;
;; (use-package multi-vterm
;;   :bind (("C-c t" . multi-vterm-project)))
;;
;; (with-eval-after-load 'vterm
;;   (setq vterm-shell (concat (executable-find "fish") " --login")))
;;

;;(use-package eat
;;;;  :hook
;;  ;; Enable Eat in Eshell to handle visual commands and terminal emulation
;;  (eshell-load . eat-eshell-mode)
;;  (eshell-load . eat-eshell-visual-command-mode)
;;  :config
;;  (setq eat-kill-buffer-on-exit t)
;;  (setq eat-term-name "xterm-256color"))
;;
;;
;;(use-package eshell
;;  :ensure nil ; Built-in
;;  :config
;;  ;; Keep eshell buffer behavior clean and terminal-like
;;  (setq eshell-scroll-to-bottom-on-input 'all
;;        eshell-scroll-to-bottom-on-output 'all
;;        eshell-kill-processes-on-exit t
;;        eshell-hist-ignoredups t
;;        eshell-destroy-buffer-when-process-dies t)
;;
;;  ;; Stop Eshell from spawning separate buffers for TUI programs.
;;  ;; This lets Eat render htop, vim, etc., natively inline.
;;  (setq eshell-visual-commands nil
;;        eshell-visual-subcommands nil
;;        eshell-visual-options nil)
;;
;;  )

(provide 'terminal-config)

;;; terminal-config.el ends here

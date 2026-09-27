;;; appearance-config.el --- Personal Emacs settings -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; Display and appearance
;; ---------------------------------------------------------------------

(use-package olivetti :commands olivetti-mode)

(defvar obp/focused-body-width 100
  "Text body width shared by focused dashboard views.")

;; get rid of emacs logo
;; (setq inhibit-startup-message t)

;; goto themes: gruvbox, twilight, doom-badger
(use-package doom-themes
  :init
  (setq doom-gruvbox-dark-variant "hard")
  :config
  ;; (load-theme 'doom-sourcerer t)
  ;; (load-theme 'doom-tomorrow-night t)
  ;; (load-theme 'doom-snazzy)
  ;; (load-theme 'plan9 t)
  (load-theme 'doom-gruvbox t)
  ;; Doom reverses Emacs 31's inheritance between these Gnus faces, creating a
  ;; cycle when Gnus loads.  Keep the empty face visually aligned with Doom's
  ;; empty mail face without inheriting from `gnus-group-news-low'.
  (custom-theme-set-faces
   'doom-gruvbox
   '(gnus-group-news-low-empty
     ((t (:inherit gnus-group-mail-1-empty :weight normal)))))
  (doom-themes-visual-bell-config))

;; Required by `doom-modeline` to display icons.
;; Run `M-x nerd-icons-install-fonts` to install the necessary fonts.
(use-package nerd-icons :defer t)

(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; Fonts and line display
(set-face-attribute 'default nil :height 130)

;; Keep actionable package and compatibility warnings visible.
(setq warning-minimum-level :warning)

;; line numbers
(column-number-mode 1)

;; Set both the type and the default buffer-local variable
;; (setq display-line-numbers-type 'relative)
;; (setq-default display-line-numbers 'relative)
(setq display-line-numbers-type 'visual)
(setq-default display-line-numbers 'visual)

;; Enable visual line numbers globally.
(global-display-line-numbers-mode 1)

;; Disable line numbers for some modes
(dolist (mode '(term-mode-hook
                shell-mode-hook
                vterm-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(global-hl-line-mode 1) ; Highlight current line

(set-fringe-mode 10)

;; ---------------------------------------------------------------------
;; Dashboard
;; ---------------------------------------------------------------------
(use-package dashboard
  :config
  (dashboard-setup-startup-hook))

(add-hook 'server-after-make-frame-hook (lambda () (dashboard-refresh-buffer)))
(setq dashboard-banner-logo-title "Welcome to Emacs")
(setq dashboard-startup-banner 'official)
(setq dashboard-center-content t)
(setq dashboard-vertically-center-content t)
(setq dashboard-show-shortcuts nil)

(setq dashboard-display-icons-p t)     ; display icons on both GUI and terminal
(setq dashboard-icon-type 'nerd-icons) ; use `nerd-icons' package

(setq dashboard-items '((recents   . 5)
                        (projects  . 5)
                        (agenda    . 20)))
(setq dashboard-item-names '(("Agenda for today:"           . "Today's agenda:")
                             ("Agenda for the coming week:" . "Agenda:")))
(setq dashboard-set-heading-icons t)
(setq dashboard-set-file-icons t)
(setq dashboard-heading-icons '((recents   . "nf-oct-history")
                                (agenda    . "nf-oct-calendar")
                                (projects  . "nf-oct-rocket")))
(setq dashboard-agenda-sort-strategy '(priority-up))

(provide 'appearance-config)

;;; appearance-config.el ends here

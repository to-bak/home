;; ---------------------------------------------------------------------
;; Package managment
;; ---------------------------------------------------------------------
(setq package-enable-at-startup nil)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install use-package with straight.el
(straight-use-package 'use-package)

;; Install packages by default in `use-package` forms,
;; without having to specify `:straight t`
(setq straight-use-package-by-default t)


;; ---------------------------------------------------------------------
;; Misc
;; ---------------------------------------------------------------------
;; https://stackoverflow.com/questions/2548673/how-do-i-get-emacs-to-evaluate-a-file-when-a-frame-is-raised
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

(use-package olivetti)

;; get rid of emacs logo
;; (setq inhibit-startup-message t)

;; goto themes: gruvbox, twilight, doom-badger
(use-package doom-themes)
;; (load-theme 'doom-sourcerer t)
;; (load-theme 'doom-tomorrow-night t)
(load-theme 'doom-badger t)
;; (load-theme 'doom-snazzy)
;; (load-theme 'plan9 t)

;; Required by `doom-modeline` to display icons.
;; Run `M-x nerd-icons-install-fonts` to install the necessary fonts.
(use-package nerd-icons)

(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; puts emacs autosave files in /tmp
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))
(setq lock-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; file backup in ~/backup
(add-to-list 'backup-directory-alist
             (cons ".*" "~/backup"))

(use-package exec-path-from-shell
  :ensure t
  :config
  ;; Only run this on macOS or Linux GUI sessions,
  ;; as terminal Emacs already has the environment.
  (when (memq window-system '(mac ns x pgtk))
    (exec-path-from-shell-initialize)))

(setenv "BOX_TESTS_PATH" "../box_tests")

;; Replace yes/no prompt with y/n
(defalias 'yes-or-no-p 'y-or-n-p)
(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 10)        ; Give some breathing room
(menu-bar-mode -1)          ; Disable the menu bar

;; fonts
(defvar efs/default-font-size 180)
(defvar efs/default-variable-font-size 180)
(set-face-attribute 'default nil :height 130)

(use-package sudo-edit)

;; In emacs the default keybindings for yank is C-y, which is kinda awkward on the hand. Use C-v instead.
;; https://www.reddit.com/r/emacs/comments/sn8pma/how_to_pasteyank_into_minibuffer_input_prompt/
(define-key minibuffer-local-map (kbd "C-v") 'yank)

;; set log-level for *Warning* buffer to :error
(setq warning-minimum-level :error)

;; line numbers
(column-number-mode 1)

;; Set both the type and the default buffer-local variable
;; (setq display-line-numbers-type 'relative)
;; (setq-default display-line-numbers 'relative)
(setq display-line-numbers-type 'visual)
(setq-default display-line-numbers 'visual)
(setq evil-respect-visual-line-mode t)

;; Toggle the global mode off, then back on to force a refresh on active buffers
(global-display-line-numbers-mode -1)
(global-display-line-numbers-mode 1)

;; Disable line numbers for some modes
(dolist (mode '(term-mode-hook
                shell-mode-hook
                vterm-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Set minimum width for line number display to 3 to avoid the gutter
;; changing size when scrolling past line 100.
(setq-default display-line-numbers-width 3)

(global-hl-line-mode 1) ; Highlight current line

(use-package vterm
  :straight nil
  :commands vterm
  :config
  (setq vterm-max-scrollback 10000
        vterm-kill-buffer-on-exit t))

(use-package multi-vterm
  :bind (("C-c t" . multi-vterm-project)))

(with-eval-after-load 'vterm
  (setq vterm-shell (concat (executable-find "fish") " --login")))

(with-eval-after-load 'evil
  (evil-set-initial-state 'vterm-mode 'emacs))

;; which-key
(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; writeable grep buffer
(use-package wgrep)

;; indentation
(setq-default indent-tabs-mode nil)

;; cleanup whitespace on save.
(add-hook 'before-save-hook 'whitespace-cleanup)

;; Automatically add a newline at the end of a file when a file is
;; saved. The POSIX standard defines a "line" as ending in a newline
;; character.
(setq require-final-newline t)

;; line-width
(setq-default fill-column 80)

(use-package hydra)

;; ---------------------------------------------------------------------
;; Eshell & Eat (Emacs Advanced Terminal)
;; ---------------------------------------------------------------------

(use-package eat
  :ensure t
  :hook
  ;; Enable Eat in Eshell to handle visual commands and terminal emulation
  (eshell-load . eat-eshell-mode)
  (eshell-load . eat-eshell-visual-command-mode)
  :config
  (setq eat-kill-buffer-on-exit t)
  (setq eat-term-name "xterm-256color"))


(use-package eshell
  :ensure nil ; Built-in
  :config
  ;; Keep eshell buffer behavior clean and terminal-like
  (setq eshell-scroll-to-bottom-on-input 'all
        eshell-scroll-to-bottom-on-output 'all
        eshell-kill-processes-on-exit t
        eshell-hist-ignoredups t
        eshell-destroy-buffer-when-process-dies t)

  ;; Stop Eshell from spawning separate buffers for TUI programs.
  ;; This lets Eat render htop, vim, etc., natively inline.
  (setq eshell-visual-commands nil
        eshell-visual-subcommands nil
        eshell-visual-options nil)

  ;; Make sure Evil doesn't interfere with terminal keybindings
  (with-eval-after-load 'evil
    (evil-set-initial-state 'eshell-mode 'emacs)
    (evil-set-initial-state 'eat-mode 'emacs)))


;; ---------------------------------------------------------------------
;; Project
;; ---------------------------------------------------------------------
(use-package project
  :ensure nil
  :bind-keymap ("C-c p" . project-prefix-map))

;; drop the prompt menu, go straight into find-file
(setq project-switch-commands #'magit-project-status)

;; ---------------------------------------------------------------------
;; Dired
;; ---------------------------------------------------------------------
(use-package dired
  :straight (:type built-in)
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom ((dired-listing-switches "-agho --group-directories-first"))
  :config
  )

;; https://stackoverflow.com/questions/1839313/how-do-i-stop-emacs-dired-mode-from-opening-so-many-buffers
(setf dired-kill-when-opening-new-dired-buffer t)
(put 'dired-find-alternate-file 'disabled nil)


;; ---------------------------------------------------------------------
;; Direnv integration
;; ---------------------------------------------------------------------
;; direnv integration
;; (use-package direnv
;; :init
;; ;; (add-hook 'prog-mode-hook #'direnv-update-environment)
;; :config
;; (direnv-mode))

;; alternative to direnv-mode
(use-package envrc)
(envrc-global-mode)


;; ---------------------------------------------------------------------
;; Dashboard
;; ---------------------------------------------------------------------
(use-package dashboard
  :ensure t
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

;; ---------------------------------------------------------------------
;; Completion
;; ---------------------------------------------------------------------
;; Enhanced completion at point with Corfu and Cape.
;; https://github.com/minad/corfu
(use-package cape)

(use-package corfu
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode)

  :config
  (setq corfu-cycle nil)                  ;; Disable cycling for `corfu-next/previous'
  (setq corfu-auto t)                     ;; Enable auto completion
  (setq corfu-scroll-margin 2)            ;; Use scroll margin
  (setq corfu-min-width 60)
  (setq corfu-max-width corfu-min-width)  ;; Always have the same width

  ;; Enable completion in the minibuffer, e.g., for commands like
  ;; `M-:' (`eval-expression') or `M-!' (`shell-command'), when other
  ;; completion UI is not active.
  (defun corfu-enable-always-in-minibuffer ()
    "Enable Corfu in the minibuffer if Vertico/Mct are not active."
    (unless (or (bound-and-true-p mct--active)
                (bound-and-true-p vertico--input)
                (eq (current-local-map) read-passwd-map))
      (setq-local corfu-auto t)         ;; Enable auto completion
      (setq-local corfu-echo-delay nil  ;; Disable automatic echo and popup
                  corfu-popupinfo-delay nil)
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)

  (setq corfu-auto-prefix 3)
  (setq corfu-popupinfo-delay 0))
;; (set-face-attribute 'corfu-current nil :inherit 'highlight :background nil :foreground nil))

(use-package vertico
  :ensure t
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)
              ("C-f" . vertico-scroll-up)
              ("C-b" . vertico-scroll-down)
              :map minibuffer-local-map
              ("<C-backspace>" . backward-kill-word))
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

;; A few more useful configurations...
(use-package emacs
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; disable recursive minibuffers (enabled in vertico config on readme page)
  (setq enable-recursive-minibuffers nil))

(use-package orderless
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(with-eval-after-load 'consult
  (setq consult-ripgrep-args
        "rg --null --line-buffered --color=never --max-columns=1000 --path-separator /   --smart-case --no-heading --with-filename --line-number --search-zip --hidden --glob=!.git/"))

;; consult
(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :config

  :bind (:map project-prefix-map
         ("b" . consult-project-buffer))

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<")) ;; "C-+")

(define-key project-prefix-map (kbd "r") 'consult-ripgrep)
(use-package consult-project-extra)

(use-package marginalia
  :after vertico
  :ensure t
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  :init
  (marginalia-mode))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  ;; Hooks it into Marginalia so icons align perfectly
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; since embark-export buffers is read-only by default
;; remove read-only before deleting line
(defun obp/evil-delete-whole-line-disable-read-only ()
  (interactive)
  (read-only-mode -1)
  (call-interactively 'evil-delete-whole-line)
  )

;; embark
(use-package embark
  :bind
  ("C-c C-o" . embark-export)
  ("C-c C-d" . obp/evil-delete-whole-line-disable-read-only))

(use-package embark-consult)


;; ---------------------------------------------------------------------
;; Latex
;; ---------------------------------------------------------------------
;; latex integration with zathura
;; (use-package tex
;; :ensure auctex)

;; (use-package pdf-tools)

;; (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer) ;; revert pdf after compile
;; (setq TeX-view-program-selection '((output-pdf "zathura"))) ;; use pdf-tools for viewing
;; (setq LaTeX-command "latex --synctex=1") ;; optional: enable synctex

;; lstlisting in latex org export
;;(use-package ox-latex)
;;(setq org-latex-listings t)

(use-package openwith
:init (openwith-mode))
(setq openwith-associations '(("\\.pdf\\'" "zathura" (file))))

;; org-babel
(org-babel-do-load-languages
 'org-babel-load-languages
 '((shell . t)
   (emacs-lisp . t)
   (python . t)
   (plantuml . t)))

;; ---------------------------------------------------------------------
;; Avy
;; ---------------------------------------------------------------------
(use-package avy)
(global-set-key (kbd "C-s") 'avy-goto-word-0)
(setq avy-timeout-seconds 0.3)

;; ---------------------------------------------------------------------
;; Evil
;; ---------------------------------------------------------------------
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-motion-state-map (kbd "C-e") 'avy-goto-char-timer)
  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(setq evil-symbol-word-search t)

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Support searching with * and # from visual selection.
;; https://github.com/bling/evil-visualstar
(use-package evil-visualstar
  :after evil
  :config
  (global-evil-visualstar-mode))

(defun obp/save-and-kill-buffer ()
  "Save the current buffer to file, then kill it."
  (interactive)
  (save-buffer)
  (kill-buffer-and-window))

;; https://emacs.stackexchange.com/questions/72394/how-to-make-q-in-spacemacs-evil-mode-kill-the-buffer-and-delete-the-window
(evil-ex-define-cmd "q" 'kill-buffer-and-window)
(evil-ex-define-cmd "wq" 'obp/save-and-kill-buffer)


;; ---------------------------------------------------------------------
;; Version control
;; ---------------------------------------------------------------------
;; https://www.reddit.com/r/emacs/comments/11auxod/magit_quits_after_a_commit_happen/
(use-package magit
  :ensure t
  :config
  (add-hook 'git-commit-post-finish-hook 'magit)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; to fetch tags with force (i.e. overriding existing tags), we allow to fetch with the --force flag enabled:
(transient-append-suffix 'magit-fetch "-t"
  '("-f" "Bypass safety checks" "--force"))

(use-package magit-delta
  :hook (magit-mode . magit-delta-mode))

;; Add magit to list of project commands
;; (add-to-list 'project-switch-commands '(magit-project-status "Magit" ?m))

;; Git gutter indicators
;; https://ianyepan.github.io/posts/emacs-git-gutter/
(use-package git-gutter
  :hook (prog-mode . git-gutter-mode)
  :config
  ;; Default is 0, meaning update indicators on saving the file.
  ;; (setq git-gutter:update-interval 0.02)
  )


;; ---------------------------------------------------------------------
;; Languages
;; ---------------------------------------------------------------------
(use-package elixir-mode)
(use-package haskell-mode)
(use-package cc-mode)
(use-package rust-mode)
(use-package nix-mode)
(use-package markdown-mode)
(use-package erlang)
(use-package protobuf-mode)
(use-package yaml-mode)
(use-package dockerfile-mode)
(use-package docker)
(use-package k8s-mode)


;; ---------------------------------------------------------------------
;; LSP (eglot, built-in from emacs 29)
;; ---------------------------------------------------------------------
;; (add-hook 'rust-mode-hook 'eglot-ensure)

(use-package dumb-jump
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate))

(setq dumb-jump-rg-search-args "--pcre2 --no-ignore -g '!_build/'")

;; ---------------------------------------------------------------------
;; Org
;; ---------------------------------------------------------------------
;; Turn on indentation and auto-fill mode for Org files
(defun dw/org-mode-setup ()
  (org-indent-mode)
  (auto-fill-mode 0)
  (visual-line-mode 1))

(use-package org
  :straight (:type built-in)
  :defer t
  :init
  ;; Must be set before org loads; makes evil motion work correctly on hidden link syntax
  (setq org-fold-core-style 'overlays)
  :hook (org-mode . dw/org-mode-setup)
  :config
  ;;(setq org-ellipsis " ▾"
  ;;    org-hide-emphasis-markers t
  ;;    org-src-fontify-natively t
  ;;    org-fontify-quote-and-verse-blocks t
  ;;    org-src-tab-acts-natively t
  ;;    org-edit-src-content-indentation 2
  ;;    org-hide-block-startup nil
  ;;    org-src-preserve-indentation nil
  ;;    org-startup-folded 'content
  ;;    org-cycle-separator-lines 2)

  (setq org-modules
        '(org-crypt
          org-habit
          org-bookmark
          org-eshell
          org-irc))

  (setq org-refile-targets '((nil :maxlevel . 2)
                             (org-agenda-files :maxlevel . 2)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  ;; Follow links in same window, use C-c & to go back
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup))

;; these following commands sets font:sizing across various levels
;; of org mode text
(with-eval-after-load 'org-faces
  (set-face-attribute 'org-document-title nil :font "JetBrainsMono Nerd Font" :weight 'bold :height 1.3))

(with-eval-after-load 'org-faces
  (dolist
      (face '((org-level-1 . 1.2)
              (org-level-2 . 1.1)
              (org-level-3 . 1.05)
              (org-level-4 . 1.0)
              (org-level-5 . 1.0)
              (org-level-6 . 1.0)
              (org-level-7 . 1.0)
              (org-level-8 . 1.0)))
    (set-face-attribute (car face) nil :font "JetBrainsMono Nerd Font" :weight 'medium :height (cdr face))))

(use-package evil-org
  :ensure t
  :after org
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar))
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-trigger 'always))

(use-package org-autolist
  :hook (org-mode . org-autolist-mode))
(add-hook 'org-mode-hook (lambda () (org-autolist-mode)))


(use-package org-modern)

(setq
 ;; Edit settings
 org-auto-align-tags nil
 org-tags-column 0
 org-catch-invisible-edits 'show-and-error
 org-special-ctrl-a/e t
 org-insert-heading-respect-content t

 ;; Org styling, hide markup etc.
 org-hide-emphasis-markers t
 org-pretty-entities t
 org-agenda-tags-column 0
 org-modern-star nil
 org-modern-hide-stars nil
 org-ellipsis "…")

(set-face-attribute 'org-modern-symbol nil :height 1.1)
(set-face-attribute 'org-modern-label nil :height 0.9)

(setq org-modern-todo-faces
      '(("TODO"      . (:background "firebrick" :foreground "whitesmoke" :weight bold))
        ("STARTED"   . (:background "firebrick" :foreground "whitesmoke" :weight bold))
        ("PARKED"   . (:background "dark goldenrod" :foreground "whitesmoke" :weight bold))
        ("BACKLOG"   . (:background "dark goldenrod" :foreground "whitesmoke" :weight bold))
        ("SOMEDAY"   . (:background "purple4" :foreground "whitesmoke" :weight bold))
        ("CLOSED"    . (:background "forest green" :foreground "whitesmoke" :weight bold))
        ("CANCELLED" . (:background "forest green" :foreground "whitesmoke" :weight bold))))

(global-org-modern-mode)

(use-package org-superstar
:after org
:hook (org-mode . org-superstar-mode)
:custom
(org-superstar-remove-leading-stars t)
(org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●")))


(use-package org-download
  :after org)
;; --- Org-Roam Standard Capture Templates ---

(defvar obp/org-roam-template-default
  `(plain "%?"
    :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                       ,(concat
                         "#+title: ${title}\n"))
    :unnarrowed t)
  "Default org-roam capture template body.")

(defvar obp/org-roam-template-contact
  `(plain
    ,(concat
      "- Email: %^{Email}\n"
      "- Department: %^{Department}\n"
      "- Project: %^{Project}\n"
      "%?")
    :target (file+head "contacts/${slug}.org"
                       ,(concat
                         "#+title: ${title}\n"
                         "#+filetags: :contact:\n"))
    :unnarrowed t)
  "Contact org-roam capture template body.")


(defvar obp/org-roam-dailies-template-meeting
  `(entry
    ,(concat
      "** %^{Meeting Title}\n"
      ":PROPERTIES:\n"
      ":TIME: %U\n"
      ":END:\n"
      "*** Attendees\n"
      "- %?\n"
      "*** Agenda\n"
      "- \n"
      "*** Notes\n"
      "- \n"
      "*** Gemini Notes\n"
      "*** Action Items\n"
      "**** TODO ")
    :target (file+head+olp "%<%Y-%m-%d>.org"
                           ,(concat
                             "#+title: %<%Y-%m-%d>\n")
                           ("Meetings")))
  "Meeting template body for org-roam dailies.")

(defvar obp/org-roam-dailies-template-journal
  `(entry
    "** %<%H:%M> %?"
    :target (file+head+olp "%<%Y-%m-%d>.org"
                           ,(concat
                             "#+title: %<%Y-%m-%d>\n")
                           ("Log")))
  "Journal/Log template body for org-roam dailies.")

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/notes/work/roam"))
  (org-roam-dailies-directory "daily/")
  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n a" . org-roam-alias-add)
         ("C-c n t" . org-roam-tag-add)
         ("C-c n T" . org-roam-tag-remove)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today)
         ("C-c n d d" . org-roam-dailies-goto-today)
         ("C-c n d y" . org-roam-dailies-capture-yesterday)
         ("C-c n d t" . org-roam-dailies-capture-tomorrow))
  :config
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))

  (setq org-roam-capture-templates
        `(("d" "default" ,@obp/org-roam-template-default)
          ("c" "contact" ,@obp/org-roam-template-contact)))

  (setq org-roam-dailies-capture-templates
        `(("m" "meeting" ,@obp/org-roam-dailies-template-meeting)
          ("j" "journal" ,@obp/org-roam-dailies-template-journal)))

  (org-roam-db-autosync-mode)
  (require 'org-roam-protocol))

(use-package org-roam-ui
  :after org-roam
  :bind (("C-c n g" . org-roam-ui-mode))
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package consult-org-roam
   :ensure t
   :after org-roam
   :custom
   ;; Use `ripgrep' for searching with `consult-org-roam-search'
   (consult-org-roam-grep-func #'consult-ripgrep)
   ;; Configure a custom narrow key for `consult-buffer'
   (consult-org-roam-buffer-narrow-key ?r)
   ;; Display org-roam buffers right after non-org-roam buffers
   ;; in consult-buffer (and not down at the bottom)
   (consult-org-roam-buffer-after-buffers t)
   :config
   ;; Activate the minor mode
   (consult-org-roam-mode 1)
   ;; Eventually suppress previewing for certain functions
   (consult-customize
    consult-org-roam-forward-links
    :preview-key "M-.")
   :bind
   ;; Define some convenient keybindings as an addition
   ("C-c n e" . consult-org-roam-file-find)
   ("C-c n b" . consult-org-roam-backlinks)
   ("C-c n B" . consult-org-roam-backlinks-recursive)
   ("C-c n l" . consult-org-roam-forward-links)
   ("C-c n r" . consult-org-roam-search))

(defun obp/force-roam-tabspace (orig-fun &rest args)
  (tabspaces-switch-or-create-workspace "roam")
  (apply orig-fun args))

(use-package org-ql
  :after org)

;; ---------------------------------------------------------------------
;; Tabspaces
;; ---------------------------------------------------------------------
(defun my/consult-project-files-and-buffers ()
  "Find files and buffers strictly within the current project."
  (interactive)
  (require 'consult)
  (if (project-current nil)
      ;; Disable global sorting so Open Buffers stay permanently on top
      (let ((vertico-sort-function nil)
            (ivy-sort-functions-alist nil))
        (consult--multi '(my/consult-source-project-open-buffers
                          my/consult-source-project-unopened-files)
                        :prompt "Project File/Buffer: "))
    (user-error "Not in a project!")))


(with-eval-after-load 'consult
  (defvar my/consult-source-project-open-buffers
    `(:name     "Project Buffers"
      :narrow   ?b
      :category buffer
      :face     consult-buffer
      :sort     nil
      ;; NEW: Intercept the string, extract the hidden buffer object, and switch to it.
      :action   ,(lambda (cand)
                   (let ((actual-buffer (get-text-property 0 'consult--candidate cand)))
                     ;; Switch to the hidden buffer object (or fallback to the string name)
                     (switch-to-buffer (or actual-buffer cand))))
      :items    ,(lambda ()
                   (when-let* ((pr (project-current nil))
                               (root (project-root pr))
                               (proj-bufs (project-buffers pr)))
                     (mapcar (lambda (b)
                               (let ((file (buffer-file-name b))
                                     (name (buffer-name b)))
                                 (if file
                                     (propertize (file-relative-name file root) 'consult--candidate b)
                                   (propertize name 'consult--candidate b))))
                             (consult--buffer-sort-visibility
                              (seq-filter (lambda (b)
                                            (not (string-prefix-p " " (buffer-name b))))
                                          (project-buffers pr))))))))

  (defvar my/consult-source-project-unopened-files
    `(:name     "Unopened Project Files"
      :narrow   ?f
      :category file
      :face     consult-file
      :action   ,(lambda (f)
                   ;; Re-attach the project root path before opening
                   (when-let ((pr (project-current nil)))
                     (find-file (expand-file-name f (project-root pr)))))
      :items    ,(lambda ()
                   (when-let* ((pr (project-current nil))
                               (root (project-root pr)))
                     (let ((all-files (project-files pr))
                           ;; Get absolute paths of open files to filter them out
                           (open-files (delq nil (mapcar #'buffer-file-name (project-buffers pr)))))
                       (delq nil
                             (mapcar (lambda (f)
                                       (unless (member f open-files)
                                         ;; Display clean relative paths in the UI
                                         (file-relative-name f root)))
                                     all-files))))))))

(defun my/consult-tabspaces-and-projects ()
  "Unified Consult interface for Tabspaces and Projects."
  (interactive)
  (require 'consult)

  (let ((vertico-sort-function nil)
        (ivy-sort-functions-alist nil))

    (consult--multi '(my/consult-source-tabspaces my/consult-source-projects)
                    :prompt "Workspace/Project: ")))

(with-eval-after-load 'consult
  (defvar my/consult-source-tabspaces
    `(:name     "Active Workspaces"
      :narrow   ?t
      :category tab
      :face     font-lock-keyword-face
      :action   ,#'tabspaces-switch-or-create-workspace
      :items    ,(lambda ()
                   (mapcar (lambda (tab) (alist-get 'name tab))
                           (tab-bar--tabs-recent)))))

  (defvar my/consult-source-projects
    `(:name     "Projects"
      :narrow   ?p
      :category project
      :face     consult-file
      :action   ,#'project-switch-project
      :items    ,#'project-known-project-roots)))

(use-package tabspaces
  :ensure t
  :hook (after-init . tabspaces-mode)
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*" "*Messages*"))

  :bind (:map project-prefix-map
              ("p" . my/consult-tabspaces-and-projects)
              ("f" . my/consult-project-files-and-buffers))

  :config

  (defun obp/force-tabspaces-on-project-switch (orig-fun dir &rest args)
    (let* ((proj (project-current nil dir))
           (name (project-name proj))
           (tab-exists (seq-find (lambda (tab) (equal name (alist-get 'name tab)))
                                 (tab-bar-tabs))))
      (tabspaces-switch-or-create-workspace name)
      (unless tab-exists
        (apply orig-fun dir args))))

  (advice-add 'org-roam-node-find :around #'obp/force-roam-tabspace)
  (advice-add 'org-roam-node-insert :around #'obp/force-roam-tabspace)
  (advice-add 'org-roam-buffer-toggle :around #'obp/force-roam-tabspace)
  (advice-add 'project-switch-project :around #'obp/force-tabspaces-on-project-switch))

(setq tab-bar-show nil)
(add-hook 'after-init-hook #'tab-bar-mode)



;; ---------------------------------------------------------------------
;; Org Agenda
;; ---------------------------------------------------------------------
(setq org-default-agenda-file (concat (file-truename "~/notes/work") "/inbox.org"))

(use-package org-super-agenda
  :ensure t
  :config
  ;; Prevent super-agenda from overriding evil hjkl on group headers
  (setq org-super-agenda-header-map (make-sparse-keymap))
  (org-super-agenda-mode t))

(add-hook 'org-agenda-mode-hook
          (lambda ()
            (setq-local olivetti-body-width 100)
            (olivetti-mode 1)))

(setq org-tag-alist
      '(("@work" . ?w)
        ("@planning" . ?p)
        ("@coding" . ?c)
        ("@meeting" . ?m)))

(setq org-tag-faces
      '(("TICKET" . (:foreground "#808080"))                           ;; Strict Hex for Gray
        ("[A-Za-z]+_[0-9]+" . (:foreground "#1e90ff" :weight bold))))  ;; Strict Hex for Dodger Blue

(setq org-agenda-prefix-format
      '((agenda . " %i %?-12t %-10s ") ;; Cleaned! Indent, Time, Schedule. No %c.
        (todo   . " %i ")
        (tags   . " %i ")
        (search . " ")))

(setq org-agenda-window-setup 'only-window)

(setq org-agenda-scheduled-leaders '("📅        " "📅 %2dx:  ")
      org-agenda-deadline-leaders  '("🚨        " "🚨 %3dd:  " "🚨 -%2dd: "))

(setq org-agenda-skip-timestamp-if-done t
      org-agenda-skip-deadline-if-done t
      org-agenda-skip-scheduled-if-done t
      org-agenda-skip-scheduled-if-deadline-is-shown t
      org-agenda-skip-timestamp-if-deadline-is-shown t
      org-agenda-start-with-log-mode nil)

(setq org-log-done 'time)
(setq org-log-into-drawer t)

(setq org-agenda-files '("~/notes/work" "~/notes/work/tickets"))

(setq org-todo-keywords
      '((sequence "TODO(t)" "STARTED(s)" "|" "CLOSED(c)")
        (sequence "PARKED(p@)" "BACKLOG(b)" "SOMEDAY(f)" "|" "CANCELLED(x@)")))

(use-package agenda-prs
  :straight nil
  :ensure nil
  :load-path "~/.emacs.d/plugins"
  :config)

(defvar obp/current-jira-ticket ""
  "Temporarily stores the Jira ticket number during org-capture.")

(defun obp/get-current-ticket ()
  "Return the current Jira ticket number for org-capture."
  obp/current-jira-ticket)

(defun obp/get-current-ticket-tag ()
  "Return the current Jira ticket with hyphens converted to underscores for safe Org tags."
  (replace-regexp-in-string "-" "_" obp/current-jira-ticket))

(defun obp/get-ticket-file-path ()
  "Prompt for a Jira ticket number and return the file path for the tickets directory."
  (setq obp/current-jira-ticket (read-string "Jira Ticket (e.g., TICKET-123): "))
  (unless (file-exists-p "~/notes/work/tickets")
    (make-directory "~/notes/work/tickets" t))
  (expand-file-name (format "%s.org" obp/current-jira-ticket) "~/notes/work/tickets/"))

(defun obp/agenda-refresh-and-redraw ()
  "Fetch fresh data and instantly update the active agenda buffer view."
  (interactive)
  (obp/refresh-prs-agenda)
  (org-agenda-redo)
  (message "Dashboard updated with fresh data!"))

(defun obp/org-agenda-in-tab ()
  "Switch to (or create) a tab named 'agenda' and open Org Agenda."
  (interactive)
  (tab-switch "agenda")
  (cd "~/notes/work/")
  (org-agenda))

(setq org-archive-location "~/notes/work/archive.org_archive::* Archive")

(defun obp/org-save-all-org-buffers (&rest _)
  "Save all org buffers, ignoring any arguments passed by the advised function."
  (org-save-all-org-buffers))

(advice-add 'org-refile :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-refile :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-todo :after 'obp/org-save-all-org-buffers) ;; Fixed typo from save-org-buffers-after-actionuffers
(advice-add 'org-agenda-deadline :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-schedule :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-priority :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-set-tags :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-add-note :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-archive :after 'obp/org-save-all-org-buffers)

(defun obp/org-agenda-skip-unmapped-and-someday ()
  "Skip entries that have dates, or belong to deferred/closed states."
  (or (org-agenda-skip-entry-if 'scheduled 'deadline)
      (when (member (org-get-todo-state) '("SOMEDAY" "PARKED" "BACKLOG" "CLOSED" "CANCELLED"))
        (save-excursion (or (outline-next-heading) (point-max))))))

(defvar obp/org-agenda-block-inbox
  '(alltodo "" ((org-agenda-overriding-header "📥 Inbox (Unprocessed Captures)")
                (org-agenda-files '("~/notes/work/inbox.org"))))
  "Inbox block for unprocessed items.")

(defvar obp/org-agenda-block-agenda
  '(agenda "" ((org-agenda-start-day "+0d")
               (org-agenda-span 18)
               (org-agenda-start-on-weekday nil)
               (org-super-agenda-groups
                '((:auto-category t)))))
  "Standard 18-day schedule/deadline agenda block.")

(defvar obp/org-agenda-block-prs
  '(alltodo "" ((org-agenda-overriding-header "🐙 Pull Requests Awaiting Review")
                (org-agenda-files '("~/notes/work/data/reviews.org"))
                (org-agenda-prefix-format '((todo . " %i ")))))
  "Block displaying pending pull requests.")

(defvar obp/org-agenda-block-unmapped
  '(alltodo "" ((org-agenda-overriding-header "Unmapped Tasks (No Schedule/Deadline)")
                (org-agenda-skip-function 'obp/org-agenda-skip-unmapped-and-someday)
                (org-super-agenda-groups
                 '((:auto-category t)))))
  "Block for tasks lacking dates, excluding SOMEDAY items.")

(defvar obp/org-agenda-block-someday
  '(todo "SOMEDAY"
         ((org-agenda-overriding-header "☁️ SOMEDAY")
          (org-super-agenda-groups
           '((:auto-category t)))))
  "Block for SOMEDAY tasks.")

(defvar obp/org-agenda-block-backlog
  '(todo "BACKLOG"
         ((org-agenda-overriding-header "☁️ BACKLOG")
          (org-super-agenda-groups
           '((:auto-category t)))))
  "Block for BACKLOG tasks, automatically grouped by category.")

(defvar obp/org-agenda-block-parked
  '(todo "PARKED"
         ((org-agenda-overriding-header "🚧 Parked")
          (org-super-agenda-groups
           '((:auto-category t))))))

(defvar obp/org-agenda-block-closed
  '(todo "CLOSED|CANCELLED"
         ((org-agenda-overriding-header "✅ Closed & Cancelled Items")
          (org-super-agenda-groups
           '((:auto-category t))))))

(defvar obp/org-agenda-block-ongoing-tickets
  '(tags "TICKET+LEVEL=1"
         ((org-agenda-overriding-header "⚡ Active Tickets Index")
          (org-agenda-files '("~/notes/work/tickets"))))
  "A simple index of all top-level ticket files.")

(defvar obp/org-agenda-block-ticket
  '(tags-todo "TICKET"
         ((org-agenda-overriding-header "🤖 Active Tickets")
          (org-agenda-files '("~/notes/work/tickets"))
          (org-super-agenda-groups
           '((:auto-category t)))))
  "Block displaying active tickets and only their actionable TODOs.")

;; --- Main Custom Commands ---

(setq org-agenda-custom-commands
      `(("d" "Dashboard"
         (,obp/org-agenda-block-inbox
          ,obp/org-agenda-block-ongoing-tickets
          ,obp/org-agenda-block-agenda
          ,obp/org-agenda-block-prs))

        ("w" "Weekly Review"
         (,obp/org-agenda-block-unmapped
          ,obp/org-agenda-block-parked
          ,obp/org-agenda-block-backlog
          ,obp/org-agenda-block-someday
          ,obp/org-agenda-block-closed))

        ("f" "☁️ Someday" (,obp/org-agenda-block-someday))
        ("b" "Backlog" (,obp/org-agenda-block-backlog))
        ("p" "🤖 Tickets" (,obp/org-agenda-block-ticket))))

;; --- Capture Templates ---

(defvar obp/org-capture-template-agenda
  '(entry
    (file+headline org-default-agenda-file "Inbox")
    "* TODO %?\nSCHEDULED: <%(org-read-date nil nil \"+1d\")>\n%a")
  "Standard capture template for agenda tasks (type, target, template).")

(defvar obp/org-capture-template-ticket
  `(plain
    (file obp/get-ticket-file-path)
    ,(concat
      "#+CATEGORY: %^{Project Category}\n"
      "#+FILETAGS: :TICKET:%(obp/get-current-ticket-tag):\n\n"
      "* %(obp/get-current-ticket) - %^{Ticket Title}\n"
      "** Context / Background\n"
      "%?\n\n"
      "** AI Guidelines\n"
      "Please adhere to the high-level guidelines in my manifest: [[id:dfac4c1b-f48b-4f6b-b55e-cb98f43d4168][AI Manifest]]\n\n"
      "** Action Items\n\n"
      "** Constraints & Exclusions\n"
      "- "))
  "Capture template for dynamic Jira Tickets.")

(setq org-capture-templates
      `(("a" "Agenda - task"      ,@obp/org-capture-template-agenda)
        ("p" "AI Prompt / Ticket" ,@obp/org-capture-template-ticket)))

(use-package org-ql
  :ensure t
  :bind (("C-c q" . org-ql-search))) ;; Bind to whatever key you prefer

(use-package org-fancy-priorities
  :ensure t
  :hook
  (org-mode . org-fancy-priorities-mode)
  :config
  (setq org-fancy-priorities-list '("🔥" "☕" "💤")))

;; C-c o prefix for org commands
(define-prefix-command 'obp/org-prefix-map)
(global-set-key (kbd "C-c o") 'obp/org-prefix-map)
(global-set-key (kbd "C-c a") 'obp/org-agenda-in-tab)
(global-set-key (kbd "C-c c") 'org-capture)

;; Global org keybindings (work everywhere)
(define-key obp/org-prefix-map (kbd "l") 'org-store-link)
(define-key obp/org-prefix-map (kbd "q") 'org-ql-search)

;; org-mode-map keybindings (org buffers only)
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c o d") 'org-deadline)
  (define-key org-mode-map (kbd "C-c o s") 'org-schedule)
  (define-key org-mode-map (kbd "C-c o p") 'org-priority)
  (define-key org-mode-map (kbd "C-c o t") 'org-set-tags-command)
  (define-key org-mode-map (kbd "C-c o n") 'org-add-note)
  (define-key org-mode-map (kbd "C-c o r") 'org-refile)
  (define-key org-mode-map (kbd "C-c o x") 'org-archive-subtree)
  (define-key org-mode-map (kbd "C-c o o") 'org-open-at-point)
  (define-key org-mode-map (kbd "C-c o L") 'org-insert-link))

;; org-agenda-mode-map keybindings (agenda view only)
(with-eval-after-load 'org-agenda
  (define-key org-agenda-mode-map (kbd "C-c o d") 'org-agenda-deadline)
  (define-key org-agenda-mode-map (kbd "C-c o s") 'org-agenda-schedule)
  (define-key org-agenda-mode-map (kbd "C-c o p") 'org-agenda-priority)
  (define-key org-agenda-mode-map (kbd "C-c o t") 'org-agenda-set-tags)
  (define-key org-agenda-mode-map (kbd "C-c o n") 'org-agenda-add-note)
  (define-key org-agenda-mode-map (kbd "C-c o r") 'org-agenda-refile)
  (define-key org-agenda-mode-map (kbd "C-c o x") 'org-agenda-archive)
  (define-key org-agenda-mode-map (kbd "C-c o o") 'org-agenda-open-link)
  (define-key org-agenda-mode-map (kbd "C-c C-c") 'obp/agenda-refresh-and-redraw)
  )


;; ---------------------------------------------------------------------
;; Window Management
;; ---------------------------------------------------------------------
(defhydra hydra-window ()
  "
Movement^^    ^Zoom^
-----------------------
_h_ ←         _+_
_j_ ↓         _-_
_k_ ↑         _0_ reset
_l_ →         _C-+_
_q_uit        _C--_
              _C-0_ global reset
"
  ("h" evil-window-decrease-width)
  ("j" evil-window-decrease-height)
  ("k" evil-window-increase-height)
  ("l" evil-window-increase-width)
  ("+" (lambda ()
         (interactive)
         (text-scale-increase 1)))
  ("-" (lambda ()
         (interactive)
         (text-scale-decrease 1)))
  ("0" (lambda ()
         (interactive)
         (text-scale-adjust 0)))
  ("C-+" (lambda ()
           (interactive)
           (global-text-scale-adjust 1)))
  ("C--" (lambda ()
           (interactive)
           (global-text-scale-adjust -1)))
  ("C-0" (lambda ()
           (interactive)
           (global-text-scale-adjust 0)))
  ("q" nil))

(global-set-key (kbd "C-c w") 'hydra-window/body)

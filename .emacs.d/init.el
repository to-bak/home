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

;; get rid of emacs logo
;; (setq inhibit-startup-message t)

;; goto themes: gruvbox, twilight, doom-badger
(use-package doom-themes)
(load-theme 'doom-badger t)
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

;; file backup in ~/backup
(add-to-list 'backup-directory-alist
             (cons ".*" "~/backup"))

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
(column-number-mode)
(global-display-line-numbers-mode t)

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

;; which-key
(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))

(use-package project :bind-keymap ("C-c p" . project-prefix-map))

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
              ("C-f" . vertico-exit)
              :map minibuffer-local-map
              ("M-h" . backward-kill-word))
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

;; consult
(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :config

  :bind (:map project-prefix-map
         ("C-c p b" . consult-project-buffer))

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

;; plantuml
;; (org-babel-do-load-languages
;; 'org-babel-load-languages
;; '((plantuml . t))) ; this line activates plantuml

;; (setq org-plantuml-jar-path
;;     (expand-file-name "/home/vchg38/Downloads/plantuml-1.2023.4.jar"))


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
(add-to-list 'project-switch-commands '(magit-project-status "Magit" ?m))

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
  :hook (org-mode . dw/org-mode-setup)
  :config
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-hide-block-startup nil
        org-src-preserve-indentation nil
        org-startup-folded 'content
        org-cycle-separator-lines 2)

  (setq org-modules
        '(org-crypt
          org-habit
          org-bookmark
          org-eshell
          org-irc))

  (setq org-refile-targets '((nil :maxlevel . 1)
                             (org-agenda-files :maxlevel . 1)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup))

;; these following commands sets font:sizing across various levels
;; of org mode text
(with-eval-after-load 'org-faces (set-face-attribute 'org-document-title nil :font "Iosevka" :weight 'bold :height 1.3))
(with-eval-after-load 'org-faces
  (dolist
      (face '((org-level-1 . 1.2)
              (org-level-2 . 1.1)
              (org-level-3 . 1.05)
              (org-level-4 . 1.0)
              (org-level-5 . 1.1)
              (org-level-6 . 1.1)
              (org-level-7 . 1.1)
              (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "Iosevka" :weight 'medium :height (cdr face))))

(use-package evil-org
  :ensure t
  :after org
  :hook (org-mode . (lambda () evil-org-mode))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(use-package org-superstar
  :after org
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-remove-leading-stars t)
  (org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●")))

(use-package org-autolist
  :hook (org-mode . org-autolist-mode))
(add-hook 'org-mode-hook (lambda () (org-autolist-mode)))

(use-package org-download
  :after org)

(defun obp/browse-org-directory ()
  (interactive)
  (let ((default-directory "~/org/"))
    (call-interactively 'find-file)))

(defhydra hydra-org-roam ()
  "
Roam^^        ^Misc^
-------------------------
_f_ind        _j_ ↓
_i_nsert      _k_ ↑
_g_raph       _q_uit
_t_ags
_r_m tags
"
  ;; :color blue closes hydra when pressed
  ("f" obp/browse-org-directory :color blue)
  ("c" (lambda ()
         (interactive)
         (org-capture nil "j"))
   :color blue)
  ("q" nil))

(global-set-key (kbd "C-c n") 'hydra-org-roam/body)


;; ---------------------------------------------------------------------
;; Org Agenda
;; ---------------------------------------------------------------------
(setq org-default-agenda-file (concat (file-truename "~/org") "/agenda.org"))
(setq org-default-journal-file (concat (file-truename "~/org") "/journal.org"))

(defun obp/open-agenda-file ()
  (interactive)
  (find-file org-default-agenda-file))

(setq org-tag-alist
      '(("@work" . ?w)
        ("@planning" . ?p)
        ("@coding" . ?c)
        ("@meeting" . ?m)))

(setq org-agenda-start-with-log-mode t)
(setq org-log-done 'time)
(setq org-log-into-drawer t)
(setq org-agenda-files (list org-default-agenda-file))
(setq org-todo-keywords
      '((sequence "TODO" "INPROGRESS" "PARKED" "DONE")))
(advice-add 'org-refile :after 'org-save-all-org-buffers)

(setq org-agenda-span 18
      org-agenda-start-on-weekday nil
      org-agenda-start-day "-7d")

;; https://stackoverflow.com/questions/7986935/using-org-capture-templates-to-schedule-a-todo-for-the-day-after-today
(setq org-capture-templates
    '(
      ("a" "agenda - add todo" entry
       (file+headline org-default-agenda-file "Inbox")
       "* TODO %?\nSCHEDULED: <%(org-read-date nil nil \"+1d\")>\n%a")

      ("j" "journal - daily entry" entry
       (file+datetree org-default-journal-file)
       " * %U - Daily Journal 1\\. How fresh did you feel today?: %^{How fresh did you feel today?} 1\\. What did I accomplish today? 2\\. What challenged me today, and how did I respond? 3\\. What am I grateful for today? 4\\. What did I learn today? 5\\. How can I improve tomorrow?" :empty-lines 1)
     )
)

(use-package org-fancy-priorities
  :ensure t
  :hook
  (org-mode . org-fancy-priorities-mode)
  :config
  (setq org-fancy-priorities-list '("🔥" "☕" "💤")))

;; since agenda.org file and org-agenda view uses
;; different functions, create wrapper to
;; to use the same function context independent,
;; by trying both functions.
(defun obp/org-or-agenda (func-agenda func-org)
  (interactive)
  (condition-case e
      (call-interactively func-agenda)
    (error
     (call-interactively func-org)
     )))

(defhydra hydra-org-agenda ()
  "
Properties^^   ^Agenda^        ^Misc^
-------------------------------------
_d_eadline     _a_genda        _j_ ↓
_s_chedule     _A_ll agenda    _k_ ↑
_p_riority     _f_ile          _q_uit
_n_ote         _c_apture
_t_ags         _C_apture
_o_rder
"
  ;; :color blue closes hydra when pressed
  ("a" (lambda ()
         (interactive)
         (org-agenda nil "n"))
   :color blue)
  ("A" org-agenda :color blue)
  ("j" evil-next-visual-line)
  ("k" evil-previous-visual-line)
  ("c" (lambda ()
         (interactive)
         (org-capture nil "a"))
   :color blue)
  ("C" org-capture :color blue)
  ("f" obp/open-agenda-file :color blue)
  ("d" (lambda ()
         (interactive)
         (obp/org-or-agenda 'org-deadline 'org-agenda-deadline)))
  ("s" (lambda ()
         (interactive)
         (obp/org-or-agenda 'org-agenda-schedule 'org-schedule)))
  ("n" (lambda ()
         (interactive)
         (obp/org-or-agenda 'org-agenda-add-note 'org-add-note))
   :color blue)
  ("t" (lambda ()
         (interactive)
         (obp/org-or-agenda 'org-agenda-set-tags 'org-set-tags-command)))
  ("o" org-toggle-ordered-property)
  ("p" (lambda ()
         (interactive)
         (obp/org-or-agenda 'org-agenda-priority 'org-priority)))
  ("l" (lambda ()
         (interactive)
         (obp/org-or-agenda 'org-agenda-set-property 'org-set-property)))
  ("q" nil))

(global-set-key (kbd "C-c a") 'hydra-org-agenda/body)


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

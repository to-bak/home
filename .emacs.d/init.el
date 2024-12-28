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

;; https://stackoverflow.com/questions/2548673/how-do-i-get-emacs-to-evaluate-a-file-when-a-frame-is-raised
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

;: get rid of emacs logo
(setq inhibit-startup-message t)

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

;; font
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


;; dired
(use-package dired
    :straight (:type built-in)
    :ensure nil
    :commands (dired dired-jump)
    :bind (("C-x C-j" . dired-jump))
    :custom ((dired-listing-switches "-agho --group-directories-first"))
    :config
)

(put 'dired-find-alternate-file 'disabled nil)

;; https://stackoverflow.com/questions/1839313/how-do-i-stop-emacs-dired-mode-from-opening-so-many-buffers
(setf dired-kill-when-opening-new-dired-buffer t)

(use-package project :bind-keymap ("C-c p" . project-prefix-map))


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

;; vertico
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

;; orderless
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
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x c" . comment-dwim)            ;; orig. bookmark-jump
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ("C-x b" . consult-buffer)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history)                ;; orig. previous-matching-history-element
         ;; Project integration
         :map project-prefix-map
         ("C-c p r" . consult-ripgrep)
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

;; marginalia
(use-package marginalia
  :after vertico
  :ensure t
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  :init
  (marginalia-mode))

;; embark
(use-package embark
  :bind
  ("C-c C-o" . embark-export))

(use-package embark-consult)

;; direnv integration
;; (use-package direnv
;; :init
;; ;; (add-hook 'prog-mode-hook #'direnv-update-environment)
;; :config
;; (direnv-mode))

;; alternative to direnv-mode
(use-package envrc)
(envrc-global-mode)

;; magit
(use-package magit
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

;; (use-package openwith
;; :init (openwith-mode))
;; (setq openwith-associations '(("\\.pdf\\'" "zathura" (file))))

;; plantuml
;; (org-babel-do-load-languages
;; 'org-babel-load-languages
;; '((plantuml . t))) ; this line activates plantuml

;; (setq org-plantuml-jar-path
;;     (expand-file-name "/home/vchg38/Downloads/plantuml-1.2023.4.jar"))


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
  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

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
;; LSP
;; ---------------------------------------------------------------------

;; (use-package lsp-mode
;;   :commands (lsp lsp-deferred)
;;   :custom
;;   (lsp-completion-provider :none)  ;; Use Corfu for LSP completion

;;   :init
;;   (setq lsp-keymap-prefix "C-c l")

;;   (defun akh/orderless-dispatch-flex-first (_pattern index _total)
;;     (and (eq index 0) 'orderless-flex))

;;   (defun akh/lsp-mode-setup-completion ()
;;     (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
;;           '(orderless)))

;;   ;; Optionally configure the first word as flex filtered.
;;   (add-hook 'orderless-style-dispatchers #'my/orderless-dispatch-flex-first nil 'local)

;;   ;; Optionally configure the cape-capf-buster.
;;   (setq-local completion-at-point-functions (list (cape-capf-buster #'lsp-completion-at-point)))

;;   :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
;;          (elixir-mode . lsp)
;;          ;;(XXX-mode . lsp)
;;          ;; if you want which-key integration
;;          (lsp-mode . lsp-enable-which-key-integration)
;;          (lsp-completion-mode . akh/lsp-mode-setup-completion))

;;   :config
;;   (setq lsp-headerline-breadcrumb-enable nil))

;; (use-package lsp-ui
;;   :config
;;   (setq lsp-ui-doc-max-height 8
;;         lsp-ui-doc-max-width 80         ; 150 (default) is too wide
;;         lsp-ui-doc-delay 0.75           ; 0.2 (default) is too naggy
;;         lsp-ui-doc-show-with-mouse nil  ; don't disappear on mouseover
;;         lsp-ui-doc-position 'at-point))

;; (setq lsp-ui-doc-enable nil)
(setq lsp-lens-enable nil)
(setq lsp-headerline-breadcrumb-enable nil)
(setq lsp-ui-sideline-enable nil)
;; (setq lsp-modeline-code-actions-enable nil)
;; (setq lsp-modeline-diagnostics-enable nil)
(setq lsp-completion-provider :none)
;; (setq lsp-diagnostics-provider :none)

;; Org
;; ---------------------------------------------------------------------

;; TODO: Mode this to another section
(setq-default fill-column 80)

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

;; (use-package org-superstar
;; :after org
;; :hook (org-mode . org-superstar-mode))
(use-package org-superstar
  :after org
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-remove-leading-stars t)
  (org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●")))

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/org/roam"))
  :bind (("C-c n f"   . org-roam-node-find)
         ("C-c n g"   . org-roam-graph)
         ("C-c n i" . org-roam-insert)
         ("C-c c" . org-capture)
         ("C-c n I" . org-roam-insert-immediate))
  :config
  ;; If you're using a vertical completion framework, you might want a more informative completion interface
  (org-roam-db-autosync-mode))

(setq org-agenda-start-with-log-mode t)
(setq org-log-done 'time)
(setq org-log-into-drawer t)
(setq org-agenda-files (list "~/org/Tasks.org"))
(setq org-todo-keywords
      '((sequence "TODO" "INPROGRESS" "PARKED" "DONE")))
(advice-add 'org-refile :after 'org-save-all-org-buffers)

(setq org-agenda-span 18
      org-agenda-start-on-weekday nil
      org-agenda-start-day "-7d")

(use-package org-autolist
  :hook (org-mode . org-autolist-mode))
(add-hook 'org-mode-hook (lambda () (org-autolist-mode)))

(use-package org-fancy-priorities
  :ensure t
  :hook
  (org-mode . org-fancy-priorities-mode)
  :config
  (setq org-fancy-priorities-list '("🔥" "☕" "💤")))

(setq org-capture-templates
      '(("a" "Agenda" entry (file+headline org-default-agenda-file "Inbox")
         "* TODO %?\n%a")
        ("n" "Roam" entry (file+headline "~/org/roam/Inbox.org" "Inbox")
         "* TODO %?\n%a")))

(use-package org-download
  :after org)

;; Org keymaps
;; ---------------------------------------------------------------------

(defun org-priority-wrapper ()
"Tries to call org-agenda-priority, followed by org-priority if former fails"
(interactive)
(condition-case e
    (org-agenda-priority)
    (error
    (org-priority))))

(defun org-schedule-wrapper ()
"Tries to call org-agenda-schedule, followed by org-schedule if former fails"
(interactive)
(condition-case e
    (org-agenda-schedule nil)
    (error
    (org-schedule nil))))

(defun org-deadline-wrapper ()
"Tries to call org-agenda-deadline, followed by org-deadline if former fails"
(interactive)
(condition-case e
    (org-agenda-deadline nil)
    (error
    (org-deadline nil))))

(defun org-set-property-wrapper ()
(interactive)
(condition-case e
    (org-agenda-set-property)
    (error
    (org-set-property))))

(defun org-add-note-wrapper ()
(interactive)
(condition-case e
    (org-agenda-add-note)
    (error
    (org-add-note))))

(defun org-set-effort-wrapper ()
(interactive)
(condition-case e
    (org-agenda-set-effort)
    (error
    (org-set-effort))))

(defun org-set-tags-wrapper ()
(interactive)
(condition-case e
    (org-agenda-set-tags)
    (error
    (org-set-tags-command))))

(defun org-set-property-wrapper ()
(interactive)
(condition-case e
    (org-agenda-set-propert)
    (error
    (org-set-property))))

(setq org-default-agenda-file (concat (file-truename "~/org") "/Tasks.org"))

(defun obp/open-agenda-file ()
  (interactive)
  (find-file org-default-agenda-file))

(define-prefix-command 'agenda-keymap)
(define-key agenda-keymap (kbd "a") 'org-agenda)
(define-key agenda-keymap (kbd "d") 'org-deadline-wrapper)
(define-key agenda-keymap (kbd "s") 'org-schedule-wrapper)
(define-key agenda-keymap (kbd "n") 'org-add-note-wrapper)
(define-key agenda-keymap (kbd "t") 'org-set-tags-wrapper)
(define-key agenda-keymap (kbd "o") 'org-toggle-ordered-property)
(define-key agenda-keymap (kbd "p") 'org-priority-wrapper)
(define-key agenda-keymap (kbd "l") 'org-set-property-wrapper)
(define-key agenda-keymap (kbd "f") 'obp/open-agenda-file)
(define-key agenda-keymap (kbd "v") 'org-insert-todo-heading)
(global-set-key (kbd "C-c a") 'agenda-keymap)

;; Hydras
;; ---------------------------------------------------------------------

(use-package hydra)


(defhydra hydra-window ()
   "
Movement^^        ^Split^         ^Switch^		^Resize^
----------------------------------------------------------------
_h_ ←           _v_ertical      _b_uffer		_q_ X←
_j_ ↓           _x_ horizontal	_f_ind files	_w_ X↓
_k_ ↑           _z_ undo        _a_ce 1		_e_ X↑
_l_ →           _Z_ reset       _s_wap		_r_ X→
_F_ollow		_D_lt Other     _S_ave		max_i_mize
_SPC_ cancel	_o_nly this     _d_elete
"
   ("h" windmove-left )
   ("j" windmove-down )
   ("k" windmove-up )
   ("l" windmove-right )
   ("q" hydra-move-splitter-left)
   ("w" hydra-move-splitter-down)
   ("e" hydra-move-splitter-up)
   ("r" hydra-move-splitter-right)
   ("b" helm-mini)
   ("f" helm-find-files)
   ("F" follow-mode)
   ("a" (lambda ()
          (interactive)
          (ace-window 1)
          (add-hook 'ace-window-end-once-hook
                    'hydra-window/body))
       )
   ("v" (lambda ()
          (interactive)
          (split-window-right)
          (windmove-right))
       )
   ("x" (lambda ()
          (interactive)
          (split-window-below)
          (windmove-down))
       )
   ("s" (lambda ()
          (interactive)
          (ace-window 4)
          (add-hook 'ace-window-end-once-hook
                    'hydra-window/body)))
   ("S" save-buffer)
   ("d" delete-window)
   ("D" (lambda ()
          (interactive)
          (ace-window 16)
          (add-hook 'ace-window-end-once-hook
                    'hydra-window/body))
       )
   ("o" delete-other-windows)
   ("i" ace-maximize-window)
   ("z" (progn
          (winner-undo)
          (setq this-command 'winner-undo))
   )
   ("Z" winner-redo)
   ("SPC" nil)
   )

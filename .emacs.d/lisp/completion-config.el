;;; completion-config.el --- Personal Emacs settings -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; Completion
;; ---------------------------------------------------------------------
;; Enhanced completion at point with Corfu and Cape.
;; https://github.com/minad/corfu
(use-package cape :defer t)

(use-package corfu
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode)

  :config
  (setq corfu-cycle nil)                  ;; Disable cycling for `corfu-next/previous'
  (setq corfu-auto t)                     ;; Enable auto completion
  (setq corfu-preselect 'first)           ;; Make TAB accept the first candidate
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

(defun obp/corfu-accept-preselected ()
  "Accept Corfu's highlighted candidate, including the preselected first one."
  (interactive)
  ;; Corfu visually preselects candidate zero while `corfu--index' remains -1.
  ;; Promote that candidate to an explicit selection before completing it.
  (when (< corfu--index 0)
    (corfu-next))
  (corfu-complete))

(with-eval-after-load 'corfu
  (keymap-set corfu-map "TAB" #'obp/corfu-accept-preselected)
  (keymap-set corfu-map "<tab>" #'obp/corfu-accept-preselected))

(use-package vertico
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
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Narrow either with this prefix key or by typing SOURCE-KEY followed by SPC.
  (setq consult-narrow-key "<"))

(define-key project-prefix-map (kbd "r") 'consult-ripgrep)

(use-package consult-project-extra
  :after consult
  :custom
  (consult-project-function #'consult-project-extra-project-fn))

(defun obp/consult-project-file-preview-state (state action candidate)
  "Forward ACTION and CANDIDATE to Consult STATE, except for image previews."
  (unless (and (eq action 'preview)
               (stringp candidate)
               (let ((case-fold-search t))
                 (string-match-p
                  "\\.\\(png\\|jpe?g\\|gif\\|svg\\|webp\\|tiff?\\|bmp\\|ico\\)\\'"
                  candidate)))
    (funcall state action candidate)))

(defun obp/consult-project-file-preview ()
  "Return a Consult file preview state which skips image previews."
  ;; init.el uses dynamic binding, so carry STATE explicitly instead of
  ;; returning a lambda that attempts to close over a local variable.
  (apply-partially #'obp/consult-project-file-preview-state
                   (consult--file-state)))

(defun obp/consult-project-files-and-buffers ()
  "Find an open buffer or any file in the selected buffer's project."
  (interactive)
  (require 'consult-project-extra)
  (let ((file-source
         (copy-sequence consult-project-extra--source-file)))
    (setf (plist-get file-source :state)
          #'obp/consult-project-file-preview)
    (let ((consult-project-extra-sources
           (list 'consult-project-extra--source-buffer file-source)))
      (consult-project-extra-find))))

(define-key project-prefix-map (kbd "f")
            #'obp/consult-project-files-and-buffers)
(define-key project-prefix-map (kbd "p") #'project-switch-project)

(use-package consult-gh
  :after consult
  :custom
  (consult-gh-prioritize-local-folder t)
  :init
  (define-prefix-command 'consult-gh-map)
  :bind
  (("C-c g" . consult-gh-map)
   :map consult-gh-map
   ("r" . consult-gh-workflow-run)
   ("l" . consult-gh-run-list)
   ("e" . consult-gh-run-rerun)
   ("c" . consult-gh-workflow-create)))

(use-package marginalia
  :after vertico
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
(defun obp/embark-delete-line ()
  "Delete the current line in a read-only export buffer."
  (interactive)
  (unless buffer-read-only
    (user-error "This command is for read-only export buffers"))
  (let ((inhibit-read-only t))
    (delete-region (line-beginning-position)
                   (min (point-max) (1+ (line-end-position))))))

;; embark
(use-package embark
  :bind
  ("C-c C-o" . embark-export)
  ("C-c C-d" . obp/embark-delete-line))

(use-package embark-consult)

(provide 'completion-config)

;;; completion-config.el ends here

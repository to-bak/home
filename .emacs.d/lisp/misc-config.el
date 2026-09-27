;;; misc-config.el --- Small personal package integrations -*- lexical-binding: t; -*-

(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns x pgtk))
    (exec-path-from-shell-initialize)))


(use-package sudo-edit :commands sudo-edit)


;; ---------------------------------------------------------------------
;; Discoverability and editing tools
;; ---------------------------------------------------------------------
(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; writeable grep buffer
(use-package wgrep :defer t)


;; ---------------------------------------------------------------------
;; Hyperbole
;; ---------------------------------------------------------------------
(use-package hyperbole
  :config
  (hyperbole-mode 1)
  (global-set-key (kbd "C-c h") #'action-key)

  (host/setup-hyperbole-links))


;; ---------------------------------------------------------------------
;; Info+
;; ---------------------------------------------------------------------
(use-package info+
  :straight nil
  :ensure nil
  :after info)


;; ---------------------------------------------------------------------
;; Elfeed
;; ---------------------------------------------------------------------
(use-package elfeed
  :bind ("C-c e" . elfeed)
  :config
  (setq elfeed-feeds
        '(
          ;; Danish News
          ("https://www.version2.dk/rss" dk tech it version2)
          ;; ("https://nyheder.tv2.dk/rss" dk news tv2)
          ("https://www.dr.dk/nyheder/service/feeds/senestenyt" dk news)

          ;; Hacker & Developer News
          ;; ("https://news.ycombinator.com/rss" hacker tech)
          ;;("http://feeds.arstechnica.com/arstechnica/index" tech longform)
          ("https://elixirforum.com/rss" elixir dev forum)

          ;; Mainstream Tech & Gadgets
          ("https://techcrunch.com/feed" tech news)
          ("https://www.theverge.com/rss/index.xml" tech news)

          ;; Artificial Intelligence
          ("https://huggingface.co/blog/feed.xml" ai dev)
          ("https://www.technologyreview.com/topic/artificial-intelligence/feed/" ai news)
          )))


;; ---------------------------------------------------------------------
;; Popper
;; ---------------------------------------------------------------------
(use-package popper
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-group-function #'popper-group-by-project)
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "Output\\*$"
          "\\*Async Shell Command\\*"
          help-mode
          compilation-mode))

  :config
  (popper-mode +1)
  (popper-echo-mode +1))


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
;; LaTeX (optional)
;; ---------------------------------------------------------------------
;; latex integration with zathura
;; (use-package tex
;; :ensure auctex)

;; (use-package pdf-tools)

;; (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer) ;; revert pdf after compile
;; (setq TeX-view-program-selection '((output-pdf "zathura"))) ;; use pdf-tools for viewing
;; (setq LaTeX-command "latex --synctex=1") ;; optional: enable synctex

;; lstlisting in LaTeX Org export
;;(use-package ox-latex)
;;(setq org-latex-listings t)


;; ---------------------------------------------------------------------
;; External file viewers
;; ---------------------------------------------------------------------
(use-package openwith
  :init (openwith-mode))

(setq openwith-associations '(("\\.pdf\\'" "zathura" (file))))


;; ---------------------------------------------------------------------
;; Avy
;; ---------------------------------------------------------------------
(use-package avy
  :bind ("C-s" . avy-goto-word-0)
  :commands avy-goto-char-timer
  :custom (avy-timeout-seconds 0.3))


;; ---------------------------------------------------------------------
;; Bazooka
;; ---------------------------------------------------------------------
(use-package hydra)

(use-package bazooka
  :straight (:type git
             :host github
             :repo "to-bak/bazooka.el"
             :branch "main")
  :demand t
  :custom
  (bazooka-capacity 4))

(defhydra obp/hydra-bazooka (:color blue :hint nil)
  "
Bazooka: _r_emember  _b_rowse  _f_lip  _x_ clear
"
  ("r" bazooka-remember)
  ("b" bazooka-consult)
  ("f" bazooka-toggle)
  ("x" bazooka-clear))


;; ---------------------------------------------------------------------
;; Window Management
;; ---------------------------------------------------------------------
(defhydra hydra-window (:inherit (obp/hydra-bazooka/heads))
  "
Movement^^    ^Zoom^             ^Bazooka^
---------------------------------------------
_h_ ←         _+_                _r_emember
_j_ ↓         _-_                _b_rowse
_k_ ↑         _0_ reset          _f_lip
_l_ →         _C-+_              _x_ clear
_q_uit        _C--_
              _C-0_ global reset
"
  ("h" shrink-window-horizontally)
  ("j" shrink-window)
  ("k" enlarge-window)
  ("l" enlarge-window-horizontally)
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

(provide 'misc-config)

;;; misc-config.el ends here

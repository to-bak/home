;;; setup-org.el --- Org editing, appearance and capture -*- lexical-binding: t; -*-

(defvar host/org-agenda-path (expand-file-name "~/org"))
(defvar host/org-agenda-inbox-path
  (expand-file-name "inbox.org" host/org-agenda-path))
(defvar host/org-agenda-reviews-path
  (expand-file-name "data/reviews.org" host/org-agenda-path))

(defun obp/org-capture-inbox-file ()
  "Return the shared inbox, creating its parent directory if needed."
  (make-directory (file-name-directory host/org-agenda-inbox-path) t)
  host/org-agenda-inbox-path)

;; ---------------------------------------------------------------------
;; Org
;; ---------------------------------------------------------------------
;; Indent outlines and wrap visually without inserting line breaks.
(defun obp/org-mode-setup ()
  (org-indent-mode 1)
  (auto-fill-mode -1)
  (visual-line-mode 1))

(define-prefix-command 'obp/org-prefix-map)
(keymap-global-set "C-c o" 'obp/org-prefix-map)

(use-package org
  ;; Register the bundled Org for Straight dependencies; do not install another copy.
  :straight (:type built-in)
  :bind (("C-c c" . org-capture)
         :map obp/org-prefix-map ("l" . org-store-link)
         :map org-mode-map
         ("C-c o d" . org-deadline)
         ("C-c o s" . org-schedule)
         ("C-c o p" . org-priority)
         ("C-c o t" . org-set-tags-command)
         ("C-c o n" . org-add-note)
         ("C-c o r" . org-refile)
         ("C-c o x" . org-archive-subtree)
         ("C-c o o" . org-open-at-point)
         ("C-c o L" . org-insert-link))
  :defer t
  :init
  ;; Use overlays for folded Org text
  (setq org-fold-core-style 'overlays)
  :hook (org-mode . obp/org-mode-setup)
  :config
  (setq org-modules
        (delq nil
              (mapcar (lambda (module)
                        (when (locate-library (symbol-name module)) module))
                      '(org-crypt org-habit org-bookmark org-eshell org-irc))))

  (setq org-use-sub-superscripts '{}
        org-export-with-sub-superscripts '{})

  (setq org-refile-targets '((nil :maxlevel . 2)
                             (org-agenda-files :maxlevel . 2)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  ;; Follow links in the same window; C-c & goes back.
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file))

(unless (equal obp/emacs-profile "phone")
  (use-package org-dispatch
    :straight nil
    :load-path (lambda () (expand-file-name "plugins/" user-emacs-directory))
    :commands org-dispatch
    :bind (:map org-mode-map ("C-c m" . org-dispatch)))

  (use-package org-dispatch-codex
    :straight nil
    :load-path (lambda () (expand-file-name "plugins/" user-emacs-directory))
    :after org-dispatch
    :demand t))

;; Load Babel backends when Org is first used.
(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)
     (emacs-lisp . t)
     (python . t)))
  (unless (equal obp/emacs-profile "phone")
    (org-babel-do-load-languages 'org-babel-load-languages
                               (append org-babel-load-languages '((plantuml . t))))))

;; these following commands sets font:sizing across various levels
;; of org mode text
(with-eval-after-load 'org-faces
  (when (display-graphic-p)
    (set-face-attribute 'org-document-title nil :font "JetBrainsMono Nerd Font" :weight 'bold :height 1.3)))

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
    (when (display-graphic-p)
      (set-face-attribute (car face) nil :font "JetBrainsMono Nerd Font" :weight 'medium :height (cdr face)))))

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
 ;;org-modern-star nil
 ;;org-modern-hide-stars nil
 org-ellipsis "…")


(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-trigger 'always))

(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :custom
  (org-modern-fold-stars
   '(("◉" . "◯")
     ("│" . "└")
     (" │" . " └")
     (" │" . " └")))
  :init
  (setq org-modern-hide-stars " ")
  :config

  (set-face-attribute 'org-modern-symbol nil :height 1.1)
  (set-face-attribute 'org-modern-label nil :height 0.9)

  (setq org-modern-todo-faces
    '(("TODO"      . (:background "firebrick" :foreground "whitesmoke" :weight bold))
          ("STARTED"   . (:background "firebrick" :foreground "whitesmoke" :weight bold))
          ("PARKED"   . (:background "dark goldenrod" :foreground "whitesmoke" :weight bold))
          ("BACKLOG"   . (:background "dark goldenrod" :foreground "whitesmoke" :weight bold))
          ("SOMEDAY"   . (:background "purple4" :foreground "whitesmoke" :weight bold))
          ("CLOSED"    . (:background "forest green" :foreground "whitesmoke" :weight bold))
          ("CANCELLED" . (:background "forest green" :foreground "whitesmoke" :weight bold))
          ("REVIEW"   . (:background "firebrick" :foreground "whitesmoke" :weight bold))
          ("AWAITING"   . (:background "cadetblue" :foreground "whitesmoke" :weight bold))
          ("DRAFT"   . (:background "dark goldenrod" :foreground "whitesmoke" :weight bold))
          ("MERGED"   . (:background "forest green" :foreground "whitesmoke" :weight bold))
          ("APPROVED"   . (:background "forest green" :foreground "whitesmoke" :weight bold))
          ("IDC"   . (:background "forest green" :foreground "whitesmoke" :weight bold)))))

(unless (equal obp/emacs-profile "phone")
  (use-package org-download
    :commands (org-download-image org-download-screenshot org-download-clipboard)
    :hook (org-mode . org-download-enable)))

(setq org-capture-templates
      (append
       '(("n" "Note" entry
          (file+headline obp/org-capture-inbox-file "Inbox")
          "* %?\n%U\n" :empty-lines 1)
         ("t" "Task" entry
          (file+headline obp/org-capture-inbox-file "Inbox")
          "* TODO %?\n%U\n" :empty-lines 1)
         ("p" "plain" entry
          (file+headline obp/org-capture-inbox-file "Inbox")
          "* TODO %?"))
       (unless (equal obp/emacs-profile "phone")
         '(("c" "code" entry
            (file+headline obp/org-capture-inbox-file "Inbox")
            "* TODO %?\n%a\n%i")
           ("b" "Clipboard" entry
            (file+headline obp/org-capture-inbox-file "Inbox")
            "* %?\n%x")
           ("w" "Webpage" entry
            (file+headline obp/org-capture-inbox-file "Inbox")
            "* TODO read later - %:annotation\n%i\n%?")))))

(use-package org-fancy-priorities
  :hook (org-mode . org-fancy-priorities-mode)
  :init
  (setq org-fancy-priorities-list '("🔥" "☕" "💤")))

;;; setup-org.el ends here

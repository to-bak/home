;;; setup-org.el --- Org editing, appearance and capture -*- lexical-binding: t; -*-

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
        '(org-crypt
          org-habit
          org-bookmark
          org-eshell
          org-irc))

  (setq org-use-sub-superscripts '{}
        org-export-with-sub-superscripts '{})

  (setq org-refile-targets '((nil :maxlevel . 2)
                             (org-agenda-files :maxlevel . 2)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  ;; Follow links in the same window; C-c & goes back.
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file))

;; Load Babel backends when Org is first used.
(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)
     (emacs-lisp . t)
     (python . t)
     (plantuml . t))))

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

(defun obp/org-item-text-start ()
  "Return the position after the current item's bullet and checkbox."
  (save-excursion
    (beginning-of-line)
    (when (looking-at org-list-full-item-re)
      (let ((checkbox-end (match-end 3)))
        (if checkbox-end
            (+ checkbox-end (if (eq (char-after checkbox-end) ?\s) 1 0))
          (match-end 1))))))

(defun obp/org-return (&optional arg)
  "Continue list items with RET; outdent or remove an empty item.
With ARG, or outside a list, use normal `org-return'."
  (interactive "P")
  (if (or arg (not (org-in-item-p))
          (and org-return-follows-link (org-in-regexp org-link-any-re)))
      (org-return arg)
    (if (and (org-at-item-p) (eolp) (<= (point) (obp/org-item-text-start)))
        (condition-case nil (org-outdent-item)
          (error (delete-region (line-beginning-position) (line-end-position))))
      (cond
       ((save-excursion (goto-char (org-in-item-p)) (org-at-item-checkbox-p))
        (org-insert-todo-heading nil))
       ((and (org-at-item-description-p)
             (> (point) (obp/org-item-text-start)) (< (point) (line-end-position)))
        (newline))
       (t (org-meta-return))))))

(defun obp/org-backspace (count)
  "Delete an item prefix at its beginning; otherwise delete COUNT characters."
  (interactive "p")
  (if (and (= count 1) (org-at-item-p)
           (<= (point) (obp/org-item-text-start)))
      (if (org-previous-line-empty-p)
          (delete-region (line-beginning-position)
                         (save-excursion (forward-line -1) (line-beginning-position)))
        (goto-char (obp/org-item-text-start))
        (if (= (line-beginning-position) (point-min))
            (delete-region (line-beginning-position) (point))
          (when (save-excursion (beginning-of-line) (looking-at-p ".*::[ \t]*$"))
            (end-of-line))
          (delete-region (point)
                         (save-excursion (forward-line -1) (line-end-position)))))
    (org-delete-backward-char count)))

(with-eval-after-load 'org
  (keymap-set org-mode-map "RET" #'obp/org-return)
  (keymap-set org-mode-map "DEL" #'obp/org-backspace)
  (keymap-set org-mode-map "<backspace>" #'obp/org-backspace))


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

(use-package org-download
  :commands (org-download-image org-download-screenshot org-download-clipboard)
  :hook (org-mode . org-download-enable))

(setq org-capture-templates
      '(("p" "plain" entry
         (file+headline org-default-agenda-file "Inbox")
         "* TODO %?")
        ("c" "code" entry
         (file+headline org-default-agenda-file "Inbox")
         "* TODO %?\n%a\n%i")
        ("b" "Clipboard" entry
         (file+headline org-default-agenda-file "Inbox")
         "* %?\n%x")
        ("w" "Webpage" entry
         (file+headline org-default-agenda-file "Inbox")
         "* TODO read later - %:annotation\n%i\n%?")))

(use-package org-fancy-priorities
  :hook (org-mode . org-fancy-priorities-mode)
  :init
  (setq org-fancy-priorities-list '("🔥" "☕" "💤")))

;;; setup-org.el ends here

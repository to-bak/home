;;; org-config.el --- Org, Org Roam, and agenda -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; Org
;; ---------------------------------------------------------------------
;; Turn on indentation and auto-fill mode for Org files
(defun obp/org-mode-setup ()
  (org-indent-mode)
  (auto-fill-mode 0)
  (visual-line-mode 1))

(use-package org
  :straight (:type built-in)
  :defer t
  :init
  ;; Use overlays for folded Org text
  (setq org-fold-core-style 'overlays)
  :hook (org-mode . obp/org-mode-setup)
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

  (setq org-use-sub-superscripts '{}
        org-export-with-sub-superscripts '{})

  (setq org-refile-targets '((nil :maxlevel . 2)
                             (org-agenda-files :maxlevel . 2)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  ;; Follow links in same window, use C-c & to go back
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file)

  (keymap-set org-mode-map "C-j" #'org-next-visible-heading)
  (keymap-set org-mode-map "C-k" #'org-previous-visible-heading)
  (keymap-set org-mode-map "M-j" #'org-metadown)
  (keymap-set org-mode-map "M-k" #'org-metaup))

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

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-trigger 'always))

(use-package org-autolist
  :hook (org-mode . org-autolist-mode))


(use-package org-modern
  :custom
  (org-modern-fold-stars
   '(("◉" . "◯")
     ("│" . "└")
     (" │" . " └")
     (" │" . " └")))
  :init
  (setq org-modern-hide-stars " "))

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
        ("IDC"   . (:background "forest green" :foreground "whitesmoke" :weight bold))))

(global-org-modern-mode)

;;(use-package org-superstar
;;:after org
;;:hook (org-mode . org-superstar-mode)
;;:custom
;;(org-superstar-remove-leading-stars t)
;;(org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●")))


(use-package org-download
  :after org)
;; --- Org-Roam Standard Capture Templates ---

(defvar obp/org-roam-template-default
  `(plain "%?\n%i"
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
      "%?\n%i")
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
  :custom
  (org-roam-directory (file-truename host/org-roam-path))
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

  (org-roam-db-autosync-mode))

(use-package org-roam-ui
  :after org-roam
  :bind (("C-c n g" . org-roam-ui-mode))
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package consult-org-roam
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


;; ---------------------------------------------------------------------
;; Org Agenda
;; ---------------------------------------------------------------------
(setq org-default-agenda-file (file-truename host/org-agenda-inbox-path))

(use-package org-super-agenda
  :config
  (org-super-agenda-mode t))

(add-hook 'org-agenda-mode-hook
          (lambda ()
            (setq-local olivetti-body-width obp/focused-body-width)
            (olivetti-mode 1)))

(setq org-tag-alist
      '(("@work" . ?w)
        ("@planning" . ?p)
        ("@coding" . ?c)
        ("@meeting" . ?m)))

;; this doesn't work with regex
(setq org-tag-faces
      '(("TICKET"           . (:foreground "#808080" :background "black"))                            ;; Gray text
        ("[A-Za-z]+_[0-9]+" . (:background "salmon" :foreground "black" :weight bold)))) ;; Salmon pill

(setq org-agenda-prefix-format
      '((agenda . " %i %?-12t %-10s ") ;; Cleaned! Indent, Time, Schedule. No %c.
        (todo   . " %i ")
        (tags   . " %i ")
        (search . " ")))

(setq org-agenda-window-setup 'current-window)

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

(setq org-agenda-files
      (list host/org-agenda-path host/org-agenda-ticket-path))

(setq org-todo-keywords
      '((sequence "TODO(t)" "STARTED(s)" "|" "CLOSED(c)")
        (sequence "PARKED(p@)" "BACKLOG(b)" "SOMEDAY(f)" "|" "CANCELLED(x@)")))

(use-package agenda-prs
  :straight nil
  :ensure nil
  :config)

(defun obp/agenda-refresh-and-redraw ()
  "Fetch fresh data and instantly update the active agenda buffer view."
  (interactive)
  (obp/refresh-prs-agenda)
  (org-agenda-redo)
  (message "Dashboard updated with fresh data!"))

(setq org-archive-location
      (concat host/org-agenda-path "/archive.org_archive::* Archive"))

(defun obp/org-save-all-org-buffers (&rest _)
  "Save all org buffers, ignoring any arguments passed by the advised function."
  (org-save-all-org-buffers))

(advice-add 'org-refile :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-refile :after 'obp/org-save-all-org-buffers)
(advice-add 'org-agenda-todo :after 'obp/org-save-all-org-buffers)
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
  `(alltodo "" ((org-agenda-overriding-header "📥 Inbox (Unprocessed Captures)")
                (org-agenda-files (list ,host/org-agenda-inbox-path))))
  "Inbox block for unprocessed items.")

(defvar obp/org-agenda-block-agenda
  '(agenda "" ((org-agenda-start-day "+0d")
               (org-agenda-span 18)
               (org-agenda-start-on-weekday nil)
               (org-super-agenda-groups
                '((:auto-category t)))))
  "Standard 18-day schedule/deadline agenda block.")

(defvar obp/org-agenda-block-prs
  `(todo "REVIEW|DRAFT|AWAITING|APPROVED"
         ((org-agenda-overriding-header "Pull Requests Awaiting Review")
          (org-agenda-files (list ,host/org-agenda-reviews-path))
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
  `(tags "TICKET+LEVEL=1"
         ((org-agenda-overriding-header "⚡ Active Tickets Index")
          (org-agenda-files (list ,host/org-agenda-ticket-path))))
  "A simple index of all top-level ticket files.")

(defvar obp/org-agenda-block-ticket
  `(tags-todo "TICKET"
              ((org-agenda-overriding-header "🤖 Active Tickets")
               (org-agenda-files (list ,host/org-agenda-ticket-path))
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

(defun obp/org-capture-url-link ()
  "Format the captured initial text as a compact HTTP(S) Org link."
  (require 'url-parse)
  (let* ((url (string-trim (or (org-capture-get :initial) "")))
         (parsed (and (string-match-p "\\`https?://" url)
                      (url-generic-parse-url url)))
         (host (and parsed (url-host parsed))))
    (unless (and host
                 (string-match-p "\\`https?://[^[:space:]]+\\'" url))
      (user-error "Select one HTTP(S) URL before using the URL template"))
    (org-link-make-string url (string-remove-prefix "www." host))))

(defvar obp/org-capture-template-todo
  '(entry
    (file+headline org-default-agenda-file "Inbox")
    "* TODO %?")
  "Context-free TODO for the Agenda inbox.")

(defvar obp/org-capture-template-code-todo
  '(entry
    (file+headline org-default-agenda-file "Inbox")
    "* TODO %?\n%a\n%i")
  "TODO linked to the source location, including any selected text.")

(defvar obp/org-capture-template-url
  '(entry
    (file+headline org-default-agenda-file "Inbox")
    "* TODO %? — %(obp/org-capture-url-link)")
  "TODO with the selected URL presented as a compact link in its heading.")

(setq org-capture-templates
      `(("p" "plain"           ,@obp/org-capture-template-todo)
        ("c" "code"            ,@obp/org-capture-template-code-todo)
        ("u" "URL"             ,@obp/org-capture-template-url)))

(use-package org-ql
  :bind (("C-c q" . org-ql-search))) ;; Bind to whatever key you prefer

(use-package org-fancy-priorities
  :hook
  (org-mode . org-fancy-priorities-mode)
  :config
  (setq org-fancy-priorities-list '("🔥" "☕" "💤")))

;; C-c o prefix for org commands
(define-prefix-command 'obp/org-prefix-map)
(global-set-key (kbd "C-c o") 'obp/org-prefix-map)
(global-set-key (kbd "C-c a") #'org-agenda)
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


(provide 'org-config)

;;; org-config.el ends here

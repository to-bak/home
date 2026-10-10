;;; setup-org-agenda.el --- Capture dashboard and PR refresh -*- lexical-binding: t; -*-

(setq org-directory host/org-agenda-path
      org-default-notes-file host/org-agenda-inbox-path
      org-default-agenda-file host/org-agenda-inbox-path)

(use-package org-super-agenda
  :demand t
  :config
  ;; Header text maps override modal keys; use the ordinary buffer maps instead.
  (setq org-super-agenda-header-map nil)
  (org-super-agenda-mode t))

(use-package olivetti
  :commands olivetti-mode)

(add-hook 'org-agenda-mode-hook
          (lambda ()
            (setq-local olivetti-body-width 100)
            (olivetti-mode 1)))

(setq org-tag-alist
      '(("@work" . ?w)
        ("@planning" . ?p)
        ("@coding" . ?c)
        ("@meeting" . ?m)))

(setq org-agenda-prefix-format
      '((agenda . " %i %?-12t %-10s ") ;; Cleaned! Indent, Time, Schedule. No %c.
        (todo   . " %i ")
        (tags   . " %i ")
        (search . " ")))

(setq org-agenda-window-setup 'current-window)

(defun obp/org-agenda-set-directory ()
  "Use the Org directory for file navigation and project discovery."
  (setq-local default-directory
              (file-name-as-directory (expand-file-name host/org-agenda-path))))

(add-hook 'org-agenda-finalize-hook #'obp/org-agenda-set-directory)

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
      (list host/org-agenda-path))

(setq org-todo-keywords
      '((sequence "TODO(t)" "STARTED(s)" "|" "CLOSED(c)")
        (sequence "PARKED(p@)" "BACKLOG(b)" "SOMEDAY(f)" "|" "CANCELLED(x@)")
        (sequence "REVIEW(r)" "DRAFT(d)" "AWAITING(a)" "|" "APPROVED(v)" "MERGED(m)" "IDC(i)")))

(setq org-archive-location
      (concat host/org-agenda-path "/archive.org_archive::* Archive"))

(defun obp/org-save-current-buffer (&rest _)
  "Save the current modified Org file after an edit has completed."
  (when (and (derived-mode-p 'org-mode) buffer-file-name (buffer-modified-p))
    (save-buffer)))

;; These hooks run in the edited file, including when editing from the agenda.
;; Log notes are stored later than the command that opens their input buffer.
(dolist (hook '(org-after-tags-change-hook org-after-note-stored-hook
                org-after-refile-insert-hook))
  (add-hook hook #'obp/org-save-current-buffer))

;; Save after the complete operation, including TODO's final cleanup.  Use the
;; underlying Org commands so the current buffer is the source, not the agenda.
;; Refile's insertion hook saves its destination; Org saves archive destinations.
(dolist (command '(org-todo org-deadline org-schedule org-priority org-refile
                   org-archive-subtree))
  (advice-add command :after #'obp/org-save-current-buffer))

(defun obp/org-agenda-skip-unmapped-and-someday ()
  "Skip entries that have dates, or belong to deferred/closed states."
  (or (org-agenda-skip-entry-if 'scheduled 'deadline)
      (when (member (org-get-todo-state) '("SOMEDAY" "PARKED" "BACKLOG" "CLOSED" "CANCELLED"))
        (save-excursion (or (outline-next-heading) (point-max))))))

(defvar obp/org-agenda-block-inbox
  `(alltodo "" ((org-agenda-overriding-header "📥 Inbox (Unprocessed Captures)")
                (org-agenda-files
                 (when (file-exists-p ,host/org-agenda-inbox-path)
                   (list ,host/org-agenda-inbox-path)))))
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
          (org-agenda-files
           (when (file-exists-p ,host/org-agenda-reviews-path)
             (list ,host/org-agenda-reviews-path)))
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

;; --- Main Custom Commands ---

(setq org-agenda-custom-commands
      `(("d" "Dashboard"
         (,obp/org-agenda-block-inbox
          ,obp/org-agenda-block-agenda
          ,obp/org-agenda-block-prs))

        ("w" "Weekly Review"
         (,obp/org-agenda-block-unmapped
          ,obp/org-agenda-block-parked
          ,obp/org-agenda-block-backlog
          ,obp/org-agenda-block-someday
          ,obp/org-agenda-block-closed))

        ("f" "☁️ Someday" (,obp/org-agenda-block-someday))
        ("b" "Backlog" (,obp/org-agenda-block-backlog))))


(defun obp/org-agenda-hide-line-numbers ()
  "Hide line numbers in generated agendas on both profiles."
  (display-line-numbers-mode 0))

(use-package org-agenda
  :straight nil
  ;; Emacs 31's visual line-number calculation can crash while rebuilding a
  ;; split agenda window. Keep line numbers in notes, not generated agendas.
  :hook (org-agenda-mode . obp/org-agenda-hide-line-numbers)
  :bind (("C-c a" . org-agenda)
         :map org-agenda-mode-map
         ("C-c o d" . org-agenda-deadline)
         ("C-c o s" . org-agenda-schedule)
         ("C-c o p" . org-agenda-priority)
         ("C-c o t" . org-agenda-set-tags)
         ("C-c o n" . org-agenda-add-note)
         ("C-c o r" . org-agenda-refile)
         ("C-c o x" . org-agenda-archive)
         ("C-c o o" . org-agenda-open-link)))

(unless (equal obp/emacs-profile "phone")
  (use-package agenda-prs
    :straight nil
    :load-path "lisp/custom"
    :demand t
    :init
    (setq agenda-prs-target-file host/org-agenda-reviews-path)
    :config
    (when (agenda-prs-configured-p)
      (agenda-prs-auto-refresh-mode 1))))

(use-package org-ql
  :bind (("C-c q" . org-ql-search)
         :map obp/org-prefix-map ("q" . org-ql-search)))

;;; setup-org-agenda.el ends here

;;; setup-org-agenda.el --- Capture dashboard and PR refresh -*- lexical-binding: t; -*-

(setq org-default-notes-file host/org-agenda-inbox-path
      org-default-agenda-file host/org-agenda-inbox-path)

(use-package org-super-agenda
  :demand t
  :config
  ;; Header text maps override modal keys; use the ordinary buffer maps instead.
  (setq org-super-agenda-header-map nil)
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
      (list host/org-agenda-path))

(setq org-todo-keywords
      '((sequence "TODO(t)" "STARTED(s)" "|" "CLOSED(c)")
        (sequence "PARKED(p@)" "BACKLOG(b)" "SOMEDAY(f)" "|" "CANCELLED(x@)")
        (sequence "REVIEW(r)" "DRAFT(d)" "AWAITING(a)" "|" "APPROVED(v)" "MERGED(m)" "IDC(i)")))

(setq org-archive-location
      (concat host/org-agenda-path "/archive.org_archive::* Archive"))

(defun obp/org-save-all-org-buffers (&rest _)
  "Save all org buffers, ignoring any arguments passed by the advised function."
  (org-save-all-org-buffers))

(dolist (command '(org-refile org-agenda-todo org-agenda-deadline
			      org-agenda-schedule org-agenda-priority org-agenda-set-tags
			      org-agenda-add-note org-agenda-archive))
  (advice-add command :after #'obp/org-save-all-org-buffers))

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


(use-package org-agenda
  :straight nil
  ;; Emacs 31's visual line-number calculation can crash while rebuilding a
  ;; split agenda window. Keep line numbers in notes, not generated agendas.
  :hook (org-agenda-mode . obp/hide-line-numbers)
  :bind (("C-c a" . org-agenda)
         :map org-agenda-mode-map
         ("C-c o d" . org-agenda-deadline)
         ("C-c o s" . org-agenda-schedule)
         ("C-c o p" . org-agenda-priority)
         ("C-c o t" . org-agenda-set-tags)
         ("C-c o n" . org-agenda-add-note)
         ("C-c o r" . org-agenda-refile)
         ("C-c o x" . org-agenda-archive)
         ("C-c o o" . org-agenda-open-link)
         ("C-c C-c" . obp/agenda-refresh-and-redraw)))

(use-package agenda-prs
  :straight nil
  :load-path "lisp/custom"
  :demand t
  :init
  (setq agenda-prs-target-file host/org-agenda-reviews-path)
  :config
  (when (agenda-prs-configured-p)
    (agenda-prs-auto-refresh-mode 1)))

(use-package org-ql
  :bind (("C-c q" . org-ql-search)
         :map obp/org-prefix-map ("q" . org-ql-search)))

;;; setup-org-agenda.el ends here

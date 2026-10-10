;;; setup-phone.el --- Built-in Org reading and capture -*- lexical-binding: t; -*-

(require 'org)
(require 'org-capture)

(defvar obp/phone-notes-directory (expand-file-name "~/org")
  "Directory containing work notes synced with Send & Receive.")
(defvar obp/phone-inbox-file
  (expand-file-name "inbox.org" obp/phone-notes-directory)
  "Shared inbox used by desktop captures and the agenda dashboard.")

(setq org-directory obp/phone-notes-directory
      org-default-notes-file obp/phone-inbox-file
      org-agenda-files (list obp/phone-notes-directory)
      org-hide-emphasis-markers t
      org-use-sub-superscripts '{}
      org-return-follows-link t
      org-ellipsis "…"
      org-agenda-window-setup 'current-window)

;; Recognize the same workflow states as the desktop without loading its agenda
;; packages, hooks, or integrations.
(setq org-todo-keywords
      '((sequence "TODO(t)" "STARTED(s)" "|" "CLOSED(c)")
        (sequence "PARKED(p@)" "BACKLOG(b)" "SOMEDAY(f)" "|" "CANCELLED(x@)")
        (sequence "REVIEW(r)" "DRAFT(d)" "AWAITING(a)" "|" "APPROVED(v)" "MERGED(m)" "IDC(i)")))

(defun obp/phone-org-mode-setup ()
  "Indent Org outlines and wrap text for the phone screen."
  (org-indent-mode 1)
  (visual-line-mode 1)
  (auto-fill-mode -1))

(add-hook 'org-mode-hook #'obp/phone-org-mode-setup)

;; Refresh unmodified buffers when Syncthing updates their files.
(global-auto-revert-mode 1)

(defun obp/phone-capture-file ()
  "Return the shared inbox file, creating its parent directory if needed."
  (make-directory (file-name-directory obp/phone-inbox-file) t)
  obp/phone-inbox-file)

(setq org-capture-templates
      '(("n" "Note" entry (file+headline obp/phone-capture-file "Inbox")
         "* %?\n%U\n" :empty-lines 1)
        ("t" "Task" entry (file+headline obp/phone-capture-file "Inbox")
         "* TODO %?\n%U\n" :empty-lines 1)))

(defun obp/phone-open-notes ()
  "Browse the synced work notes."
  (interactive)
  (dired obp/phone-notes-directory))

(keymap-global-set "C-c n" #'obp/phone-open-notes)
(keymap-global-set "C-c c" #'org-capture)
(keymap-global-set "C-c a" #'org-agenda)
(keymap-global-set "C-c l" #'org-store-link)

;;; setup-phone.el ends here

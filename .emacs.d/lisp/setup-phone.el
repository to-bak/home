;;; setup-phone.el --- Org profile for Termux -*- lexical-binding: t; -*-

(defvar obp/phone-notes-directory (expand-file-name "~/org")
  "Directory containing work notes synced with Send & Receive.")

;; Use the same Org modules and relative inbox/review paths as the desktop.
(setq host/org-agenda-path obp/phone-notes-directory
      host/org-agenda-inbox-path
      (expand-file-name "inbox.org" obp/phone-notes-directory)
      host/org-agenda-reviews-path
      (expand-file-name "data/reviews.org" obp/phone-notes-directory))

(load (expand-file-name "lisp/setup-org.el" user-emacs-directory) nil 'nomessage)
(load (expand-file-name "lisp/setup-org-agenda.el" user-emacs-directory) nil 'nomessage)

(setq org-return-follows-link t)

;; Refresh unmodified buffers when Syncthing updates their files.
(global-auto-revert-mode 1)

(defun obp/phone-open-notes ()
  "Browse the synced work notes."
  (interactive)
  (dired obp/phone-notes-directory))

(keymap-global-set "C-c n" #'obp/phone-open-notes)
(keymap-global-set "C-c l" #'org-store-link)

;;; setup-phone.el ends here

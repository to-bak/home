;;; setup-org-roam.el --- Notes and daily captures -*- lexical-binding: t; -*-

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
  :demand t
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

  (org-roam-db-autosync-mode 1))

(use-package org-roam-ui
  :bind (("C-c n g" . org-roam-ui-mode))
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package consult-org-roam
  :after org-roam
  :demand t
  :custom
  ;; Use `ripgrep' for searching with `consult-org-roam-search'
  (consult-org-roam-grep-func #'consult-ripgrep)
  ;; Keep r for recent files and use n for notes in `consult-buffer'
  (consult-org-roam-buffer-narrow-key ?n)
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



;; Restore the note-based instruction catalog without loading Cockpit eagerly.
(with-eval-after-load 'agent-shell-cockpit
  (require 'agent-shell-cockpit-org-roam)
  (setq agent-shell-cockpit-instructions
        '((manifest :title "AI Manifest"
                    :source (org-roam "a8a767a1-1644-4c4a-a05f-23f7b3eab5bf")))))
;; The current Cockpit Org-roam adapter provides its own resolution instructions;
;; the old agent-shell-cockpit-skills module no longer exists.

;;; setup-org-roam.el ends here

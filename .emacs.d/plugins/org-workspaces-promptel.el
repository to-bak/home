;;; org-workspaces-promptel.el --- Workspace sources for Promptel -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;;; Commentary:
;; Composition starts with no attachments.  Workspace sections and files can
;; be attached explicitly inside Promptel.  Org metadata is never changed here.
;;; Code:
(require 'org-workspaces)
(require 'prompt-compose)
(defcustom org-workspaces-promptel-extra-context-ids nil
  "Additional Org heading IDs offered in Promptel's workspace section picker."
  :type '(repeat string)
  :group 'org-workspaces)

(defun org-workspaces-promptel-section (entry)
  "Return ENTRY's own body as a labeled text attachment, without children."
  (org-with-point-at entry
    (org-with-wide-buffer
     (let ((label (org-get-heading t t t t)))
       (org-end-of-meta-data t)
       (list :kind 'text :label label
             :text (string-trim
                    (buffer-substring-no-properties
                     (point) (save-excursion (outline-next-heading) (point)))))))))

(defun org-workspaces-promptel-context (routing)
  "Select workspace sections or a file for the draft described by ROUTING."
  (let* ((id (plist-get routing :workspace-id))
         (workspace (and id (org-workspaces-find-id id))))
    (unless workspace (user-error "Workspace heading missing; open its Org file first"))
    (pcase (completing-read "Workspace context: " '("Org sections" "Workspace file") nil t)
      ("Org sections"
       (let* ((entries (delete-dups
                        (append (list workspace) (org-workspaces-entries workspace)
                                (delq nil (mapcar #'org-workspaces-find-id
                                                 org-workspaces-promptel-extra-context-ids)))))
              (choices
               (cl-loop for entry in entries
                        unless (org-workspaces-get entry "OW_KIND")
                        for attachment = (org-workspaces-promptel-section entry)
                        unless (string-empty-p (plist-get attachment :text))
                        collect (cons (org-with-point-at entry
                                        (format "%s — %s:%d" (org-get-heading t t t t)
                                                (buffer-name) (line-number-at-pos))) attachment))))
         (unless choices (user-error "No nonempty Org sections in this workspace"))
         (mapcar (lambda (name) (cdr (assoc name choices)))
                 (completing-read-multiple "Attach sections (own body, no children): " choices nil t))))
      ("Workspace file"
       (let ((path (expand-file-name
                    (read-file-name "Attach workspace file: "
                                    (org-workspaces-root workspace) nil t))))
         (unless (file-regular-p path) (user-error "Choose a file; use -f to attach a directory"))
         (list (list :kind 'file :path path :label (file-name-nondirectory path))))))))

(defun org-workspaces-promptel-compose ()
  "Open an empty Promptel draft associated with the workspace root."
  (interactive)
  (let* ((workspace (org-workspaces-resolve))
         (directory (org-workspaces-initialize workspace)))
    (prompt-compose-open
     :routing (list :workspace-id (org-workspaces-get workspace "ID")
                    :directory directory))))

(prompt-compose-register-context-source
 "Workspace" #'org-workspaces-promptel-context
 (lambda (routing) (plist-get routing :workspace-id)))
(define-key org-workspaces-map (kbd "p") #'org-workspaces-promptel-compose)
(provide 'org-workspaces-promptel)
;;; org-workspaces-promptel.el ends here

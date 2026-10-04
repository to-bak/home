;;; org-workspaces.el --- Org headings as workspaces -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1") (org "9.6"))
;;; Commentary:
;; Workspace membership and context are ordinary Org metadata.  No AI dependency.
;; Edits are left in the Org buffer for normal saving.  No automatic cleanup.
;;; Code:
(require 'org)
(require 'org-id)
(require 'cl-lib)
(require 'subr-x)
(defvar org-agenda-custom-commands)
(defvar org-super-agenda-mode)
(defvar org-agenda-overriding-header)
(defvar org-agenda-finalize-hook)
(declare-function org-super-agenda-mode "org-super-agenda" (&optional arg))
(defgroup org-workspaces nil "Workspaces in Org." :group 'org)
(defcustom org-workspaces-root-directory "~/.workspaces/org-workspaces/"
  "Parent directory for physical workspaces, each named by its Org ID."
  :type 'directory)
(defvar org-workspaces-agenda-sections-functions nil
  "Functions returning propertized section text to place above workspace rows.
Optional row properties: org-workspaces-open-function and org-workspaces-id.")
(defvar org-workspaces-agenda-workspace-functions nil
  "Functions called with a workspace marker to render rows beneath it.
Each returns a propertized string. Rendering must not modify Org files.")

(defcustom org-workspaces-files nil
  "Org files or directories to search, in addition to agenda and open files."
  :type '(repeat file))
(defvar org-workspaces-map (make-sparse-keymap) "Workspace command prefix.")

(defun org-workspaces-files ()
  "Return existing files used for workspace discovery."
  (delete-dups
   (cl-remove-if-not
    #'file-exists-p
    (append
     (cl-mapcan (lambda (path)
                  (if (file-directory-p path)
                      (directory-files-recursively path "\\.org\\'")
                    (list (expand-file-name path)))) org-workspaces-files)
     (org-agenda-files t)
     (cl-loop for buffer in (buffer-list)
              when (with-current-buffer buffer (derived-mode-p 'org-mode))
              when (buffer-file-name buffer) collect (buffer-file-name buffer))))))

(defun org-workspaces-current ()
  "Return the containing workspace marker, including from agenda entries."
  (if (derived-mode-p 'org-agenda-mode)
      (progn
        (org-workspaces-agenda-repair-source)
        (or (when-let* ((id (org-get-at-bol 'org-workspaces-id)))
              (org-workspaces-find-id id))
        (when-let* ((marker (org-get-at-bol 'org-hd-marker)))
        (with-current-buffer (marker-buffer marker)
          (save-excursion (goto-char marker) (org-workspaces-current))))))
    (when (derived-mode-p 'org-mode)
      (save-excursion
        (save-restriction
          (widen)
          (unless (org-before-first-heading-p)
            (org-back-to-heading t)
            (while (and (not (equal (org-entry-get nil "OW_WORKSPACE") "t"))
                        (org-up-heading-safe)))
            (when (equal (org-entry-get nil "OW_WORKSPACE") "t")
              (point-marker))))))))

(defun org-workspaces-candidates ()
  "Return workspace labels and markers from configured files."
  (let (result ids)
    (dolist (file (org-workspaces-files))
      (with-current-buffer (find-file-noselect file)
        (org-with-wide-buffer
         (org-map-entries
          (lambda ()
            (when (equal (org-entry-get nil "OW_WORKSPACE") "t")
              (let ((id (org-entry-get nil "ID")))
                (when (and id (member id ids))
                  (user-error "Duplicate workspace ID %s; regenerate the copied heading's ID" id))
                (push id ids)
                (push (cons (format "%s — %s:%d" (org-get-heading t t t t)
                                    (abbreviate-file-name file) (line-number-at-pos))
                            (point-marker)) result)))) nil 'file))))
    (nreverse result)))

(defun org-workspaces-read ()
  "Choose a workspace and return its marker."
  (let ((choices (org-workspaces-candidates)))
    (unless choices (user-error "No workspaces; mark an Org heading with C-c o w w"))
    (cdr (assoc (completing-read "Workspace: " choices nil t) choices))))

(defun org-workspaces-resolve ()
  "Use the workspace at point or choose one."
  (or (org-workspaces-current) (org-workspaces-read)))

(defun org-workspaces-find ()
  "Visit a workspace through completion."
  (interactive)
  (org-goto-marker-or-bmk (org-workspaces-read)))

(defun org-workspaces-mark ()
  "Initialize this heading as a workspace with an Org ID and physical directory."
  (interactive)
  (unless (and (derived-mode-p 'org-mode) buffer-file-name)
    (user-error "Visit an Org file and place point on a heading first"))
  (org-back-to-heading t)
  (org-entry-put nil "OW_WORKSPACE" "t")
  (org-id-get-create)
  (org-workspaces-initialize (point-marker))
  (message "Workspace initialized; save the Org file normally"))

(defun org-workspaces--component (name)
  "Validate NAME as a single directory component."
  (unless (and (stringp name) (not (string-empty-p name))
               (not (member name '("." "..")))
               (not (string-match-p "[/\\\\\n\r]" name)))
    (user-error "Use a single directory name: %s" name))
  name)

(defun org-workspaces-root (workspace)
  "Return the physical root for WORKSPACE without creating it."
  (file-name-as-directory
   (expand-file-name
    (org-workspaces--component
     (or (org-workspaces-get workspace "ID") (user-error "Workspace has no Org ID")))
    (expand-file-name org-workspaces-root-directory))))

(defun org-workspaces--link (source destination)
  "Link SOURCE at DESTINATION; never overwrite an existing resource."
  (cond
   ((and (file-exists-p destination)
         (file-equal-p source destination)) destination)
   ((or (file-exists-p destination) (file-symlink-p destination))
    (user-error "Workspace destination already exists: %s" destination))
   (t (make-symbolic-link (directory-file-name source) destination) destination)))

(defun org-workspaces-initialize (&optional workspace)
  "Create WORKSPACE's root, repos and files directories.
Existing directory members are linked into repos without moving their sources.
This operation is idempotent and does not edit Org metadata."
  (interactive)
  (let* ((workspace (or workspace (org-workspaces-resolve)))
         (root (org-workspaces-root workspace)))
    (dolist (directory (list root (expand-file-name "repos" root)
                            (expand-file-name "files" root)))
      (when (file-symlink-p (directory-file-name directory))
        (user-error "Workspace storage directory is a symbolic link: %s" directory))
      (make-directory directory t))
    (dolist (entry (org-workspaces-entries workspace "directory"))
      (let* ((source (org-workspaces-directory entry))
             (name (org-with-point-at entry (org-get-heading t t t t)))
             (target (expand-file-name (org-workspaces--component name)
                                       (expand-file-name "repos" root))))
        (when (file-directory-p source)
          (org-workspaces--link source target))))
    root))

(defun org-workspaces-find-id (id)
  "Find ID in live Org buffers first, including unsaved headings.
Fall back to Org's persistent index only when no live heading matches."
  (or (catch 'found
        (dolist (buffer (buffer-list))
          (with-current-buffer buffer
            (when (derived-mode-p 'org-mode)
              (org-with-wide-buffer
               (goto-char (point-min))
               (while (re-search-forward org-heading-regexp nil t)
                 (when (equal (org-entry-get nil "ID") id)
                   (org-back-to-heading t)
                   (throw 'found (point-marker)))))))))
      (org-id-find id t)))

(defun org-workspaces-get (workspace property)
  "Read PROPERTY at WORKSPACE without inheritance."
  (org-with-point-at workspace (org-entry-get nil property)))

(defun org-workspaces-put (workspace property value)
  "Set PROPERTY to VALUE at WORKSPACE; nil removes it."
  (org-with-point-at workspace
    (unless (equal (org-entry-get nil property) value)
      (unless (verify-visited-file-modtime (current-buffer))
        (user-error "Workspace file changed on disk; reconcile the Org buffer before editing metadata"))
      (if value (org-entry-put nil property value)
        (org-entry-delete nil property)))))

(defun org-workspaces-entries (workspace &optional kind)
  "Return descendants of WORKSPACE, optionally restricted to OW_KIND KIND.
Nested workspaces own their descendants."
  (org-with-point-at workspace
    (org-with-wide-buffer
     (let ((end (save-excursion (org-end-of-subtree t t))) result)
       (forward-line 1)
       (while (re-search-forward org-heading-regexp end t)
         (beginning-of-line)
         (when (and (equal (org-workspaces-current) workspace)
                    (or (not kind) (equal (org-entry-get nil "OW_KIND") kind)))
           (push (point-marker) result))
         (forward-line 1))
       (nreverse result)))))

(defun org-workspaces-add-entry (workspace title kind properties)
  "Append an entry with TITLE, KIND and PROPERTIES under WORKSPACE."
  (when (string-match-p "[\n\r]" title) (user-error "Entry names must be one line"))
  (org-with-point-at workspace
    (org-with-wide-buffer
     (let ((level (1+ (org-outline-level))))
       (org-end-of-subtree t t)
       (unless (bolp) (insert "\n"))
       (insert (make-string level ?*) " " title "\n")
       (forward-line -1)
       (org-entry-put nil "OW_KIND" kind)
       (dolist (property properties) (org-entry-put nil (car property) (cdr property)))
       (org-id-get-create)
       (point-marker)))))

(defun org-workspaces-directory (entry)
  "Return the absolute directory recorded on ENTRY."
  (org-with-point-at entry
    (file-name-as-directory
     (expand-file-name (or (org-entry-get nil "OW_DIRECTORY")
                          (user-error "Entry has no directory"))
                      (file-name-directory buffer-file-name)))))

(defun org-workspaces-read-directory (workspace)
  "Choose a member directory of WORKSPACE, or an explicit other directory."
  (let* ((choices (mapcar (lambda (entry)
                           (cons (org-with-point-at entry
                                   (format "%s — %s" (org-get-heading t t t t)
                                           (org-workspaces-directory entry)))
                                 (org-workspaces-directory entry)))
                         (org-workspaces-entries workspace "directory")))
         (choice (completing-read "Directory: " (cons "Other directory…" choices) nil t))
         (path (or (cdr (assoc choice choices))
                   (read-directory-name "Directory: " nil nil t))))
    (unless (file-directory-p path) (user-error "Directory is missing: %s" path))
    (file-name-as-directory (expand-file-name path))))

(defun org-workspaces-add-directory (&optional workspace directory name)
  "Link a named DIRECTORY into WORKSPACE/repos and record its membership."
  (interactive)
  (let* ((workspace (or workspace (org-workspaces-resolve)))
         (directory (file-name-as-directory
                     (expand-file-name (or directory (read-directory-name "Directory: " nil nil t)))))
         (name (or name (read-string "Member name: "
                                    (file-name-nondirectory (directory-file-name directory)))))
         (existing (cl-find-if (lambda (entry)
                                (org-with-point-at entry (equal name (org-get-heading t t t t))))
                              (org-workspaces-entries workspace "directory"))))
    (unless (file-directory-p directory) (user-error "Missing directory: %s" directory))
    (let* ((root (org-workspaces-initialize workspace))
           (target (expand-file-name (org-workspaces--component name)
                                     (expand-file-name "repos" root))))
      (org-workspaces--link directory target)
      (if existing (org-workspaces-put existing "OW_DIRECTORY" (file-name-as-directory target))
        (org-workspaces-add-entry workspace name "directory"
                                  `(("OW_DIRECTORY" . ,(file-name-as-directory target))))))))

(defun org-workspaces-open-directory ()
  "Open the physical workspace root in Dired."
  (interactive)
  (dired (org-workspaces-initialize (org-workspaces-resolve))))

(defun org-workspaces-create-worktree (&optional choose-name)
  "Create a worktree under repos using the repository name.
Choose a local branch, or enter a new branch name to create it from HEAD.
With prefix CHOOSE-NAME, choose an alternative member name."
  (interactive "P")
  (let* ((workspace (org-workspaces-resolve))
         (repository (directory-file-name
                      (expand-file-name (read-directory-name "Repository: " nil nil t))))
         (name (file-name-nondirectory repository))
         (name (if choose-name (read-string "Member name: " name) name))
         (root (org-workspaces-initialize workspace))
         (directory (expand-file-name (org-workspaces--component name)
                                      (expand-file-name "repos" root)))
         (branches (with-temp-buffer
                     (unless (zerop (process-file "git" nil t nil "-C" repository
                                                  "for-each-ref" "--format=%(refname:short)" "refs/heads/"))
                       (user-error "Cannot read repository branches: %s" (buffer-string)))
                     (split-string (buffer-string) "\n" t)))
         (branch (completing-read "Branch (existing or new): " branches nil nil nil nil
                                  (concat "workspace/" (org-workspaces-get workspace "ID")))))
    (when (or (string-empty-p branch) (string-prefix-p "-" branch)
              (file-exists-p directory) (file-symlink-p directory))
      (user-error "Use a valid branch and unused member name (C-u C-c o w t changes the name)"))
    (with-temp-buffer
      (unless (zerop (apply #'process-file "git" nil t nil "-C" repository "worktree" "add"
                           (if (member branch branches) (list directory branch)
                             (list "-b" branch directory "HEAD"))))
        (user-error "Git worktree creation failed: %s" (string-trim (buffer-string)))))
    (org-workspaces-add-directory workspace directory name)))

(defun org-workspaces-add-resource (&optional copy workspace source name)
  "Link a file or directory into WORKSPACE/files; with prefix COPY, copy it.
SOURCE and NAME may be supplied programmatically.  Existing paths are preserved."
  (interactive "P")
  (let* ((workspace (or workspace (org-workspaces-resolve)))
         (source (expand-file-name (or source (read-file-name "Resource: " nil nil t))))
         (root (org-workspaces-initialize workspace))
         (name (org-workspaces--component
                (or name (read-string "Resource name: "
                                      (file-name-nondirectory (directory-file-name source))))))
         (target (expand-file-name name (expand-file-name "files" root))))
    (unless (file-exists-p source) (user-error "Resource missing: %s" source))
    (when (or (file-exists-p target) (file-symlink-p target))
      (user-error "Resource already exists: %s" target))
    (if copy
        (if (file-directory-p source)
            (progn
              (when (file-in-directory-p target source)
                (user-error "Cannot copy a directory into itself"))
              (copy-directory source target nil t t))
          (copy-file source target nil))
      (make-symbolic-link (directory-file-name source) target))
    (org-workspaces-add-entry workspace name "resource"
                              `(("OW_FILE" . ,target)
                                ("OW_RESOURCE_MODE" . ,(if copy "copy" "link"))))
    target))

(defun org-workspaces-agenda-repair-source (&rest _arguments)
  "Restore a killed source buffer for the workspace agenda row at point.
Ordinary agenda entries without workspace location metadata are untouched."
  (when (derived-mode-p 'org-agenda-mode)
    (when-let* ((location (org-get-at-bol 'org-workspaces-source))
                (old (org-get-at-bol 'org-hd-marker))
                ((not (marker-buffer old))))
      (let ((file (car location)) (id (cdr location)) marker)
        (unless (file-exists-p file)
          (user-error "Workspace file is missing: %s" file))
        (with-current-buffer (find-file-noselect file)
          (org-with-wide-buffer
           (goto-char (point-min))
           (while (and (not marker) (re-search-forward org-heading-regexp nil t))
             (when (equal id (org-entry-get nil "ID"))
               (org-back-to-heading t)
               (setq marker (point-marker))))))
        (unless marker
          (user-error "Workspace heading was moved or removed; refresh the agenda"))
        (let ((inhibit-read-only t))
          (add-text-properties (line-beginning-position) (line-end-position)
                               (list 'org-marker marker 'org-hd-marker marker)))))))

(defun org-workspaces-agenda-visit (original &rest arguments)
  "Visit an adapter row or call ORIGINAL with ARGUMENTS for an Org row."
  (if-let* (((derived-mode-p 'org-agenda-mode))
             (open (org-get-at-bol 'org-workspaces-open-function)))
      (funcall open)
    (org-workspaces-agenda-repair-source)
    (apply original arguments)))

(defun org-workspaces-agenda-separator ()
  "Return a divider using the normal agenda block separator setting."
  (let ((separator org-agenda-block-separator))
    (concat (cond ((characterp separator)
                   (make-string (max 1 (1- (window-body-width))) separator))
                  ((stringp separator) separator)
                  (t "")) "\n")))

(defun org-workspaces-agenda-appearance ()
  "Apply presentation only to the workspace agenda."
  (when (equal org-agenda-overriding-header "Workspaces")
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (when-let* ((marker (org-get-at-bol 'org-hd-marker))
                      ((marker-buffer marker))
                      (file (buffer-file-name (marker-buffer marker)))
                      (id (org-workspaces-get marker "ID")))
            (put-text-property (line-beginning-position) (line-end-position)
                               'org-workspaces-source (cons file id)))
          (forward-line 1))))
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (let ((workspace (org-get-at-bol 'org-hd-marker)))
            (if (not workspace)
                (forward-line 1)
              (add-face-text-property (line-beginning-position) (line-end-position)
                                      'org-super-agenda-header t)
              (forward-line 1)
              (dolist (function org-workspaces-agenda-workspace-functions)
                (insert (funcall function workspace)))
              (insert "\n"))))))
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-min))
        (dolist (function org-workspaces-agenda-sections-functions)
          (insert (funcall function)))))
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^Workspaces$" nil t)
        (let ((inhibit-read-only t))
          (replace-match (propertize "📁 Workspaces" 'face 'org-agenda-structure) t t))))
    (display-line-numbers-mode -1)
    (use-local-map (copy-keymap (current-local-map)))
    (local-set-key (kbd "C-c o w") org-workspaces-map)
    (setq-local header-line-format nil)
    (goto-char (point-min))
    (while (and (not (eobp)) (not (or (org-get-at-bol 'org-hd-marker)
                                   (org-get-at-bol 'org-workspaces-open-function))))
      (forward-line 1))))

(defun org-workspaces-agenda-install ()
  "Register W in the agenda dispatcher without changing other views.
Workspace file discovery is evaluated again on agenda refresh."
  (require 'org-agenda)
  (require 'org-super-agenda)
  (dolist (command '(org-agenda-goto org-agenda-switch-to))
    (advice-remove command #'org-workspaces-agenda-repair-source)
    (unless (advice-member-p #'org-workspaces-agenda-visit command)
      (advice-add command :around #'org-workspaces-agenda-visit)))
  (add-hook 'org-agenda-finalize-hook #'org-workspaces-agenda-appearance)
  (unless org-super-agenda-mode (org-super-agenda-mode 1))
  (let ((command
         '("W" "Workspaces" tags "OW_WORKSPACE=\"t\""
           ((org-agenda-files (org-workspaces-files))
            (org-agenda-overriding-header "Workspaces")
            (org-agenda-prefix-format '((tags . "  ")))
            (org-agenda-remove-tags t)
            (org-super-agenda-header-prefix "")
            (org-use-property-inheritance nil)
            (org-agenda-sorting-strategy '(todo-state-up priority-down category-keep))
            (org-super-agenda-groups nil)))))
    (setf (alist-get "W" org-agenda-custom-commands nil nil #'equal)
          (cdr command))))

(defun org-workspaces-agenda ()
  "Open workspace headings in a standard agenda with TODO states inline.
Use normal agenda commands and the C-c o w prefix on the selected workspace."
  (interactive)
  (org-workspaces-agenda-install)
  (org-agenda nil "W"))

(dolist (binding '(("v" . org-workspaces-agenda) ("w" . org-workspaces-mark) ("f" . org-workspaces-find)
                   ("i" . org-workspaces-initialize) ("l" . org-workspaces-add-resource)
                   ("d" . org-workspaces-add-directory) ("r" . org-workspaces-open-directory)
                   ("t" . org-workspaces-create-worktree)))
  (define-key org-workspaces-map (kbd (car binding)) (cdr binding)))
;; Also remove the previous binding when this file is hotloaded.
(define-key org-workspaces-map (kbd "c") nil)
(provide 'org-workspaces)
;;; org-workspaces.el ends here

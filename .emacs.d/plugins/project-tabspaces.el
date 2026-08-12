;;; project-tabspaces.el --- Tabspaces and project.el integration -*- lexical-binding: t; -*-

;; Author: You
;; Description: Seamlessly integrate project.el commands with tabspaces.

(require 'project)
(require 'consult)
(require 'tabspaces)
(require 'seq)

(defgroup project-tabspaces nil
  "Integration between project.el and tabspaces."
  :group 'tabspaces)

(defconst project-tabspaces--root-parameter 'project-tabspaces-root
  "Tab parameter used to store the exact project root.")

(defvar project-tabspaces--consult-project nil
  "Project captured for the duration of a Consult command.")

;; Optional completion frontends; declaring them preserves dynamic binding
;; when this file is byte-compiled without loading those packages first.
(defvar vertico-sort-function)
(defvar ivy-sort-functions-alist)

(defun project-tabspaces--normalize-root (root)
  "Return a canonical directory name for project ROOT."
  (file-name-as-directory (expand-file-name root)))

(defun project-tabspaces--tab-root (&optional tab)
  "Return the project root recorded on TAB, or the current tab."
  (let* ((tab (or tab (tab-bar--current-tab-find)))
         (name (alist-get 'name tab)))
    (when-let ((root (or (alist-get project-tabspaces--root-parameter tab)
                         (car (rassoc name tabspaces-project-tab-map)))))
      (project-tabspaces--normalize-root root))))

(defun project-tabspaces--set-current-tab-root (root)
  "Record project ROOT on the current tab."
  (let* ((tab (tab-bar--current-tab-find))
         (name (alist-get 'name tab))
         (root (project-tabspaces--normalize-root root)))
    (setf (alist-get project-tabspaces--root-parameter (cdr tab)) root)
    ;; Tabspaces writes this map to its session file.
    (setq tabspaces-project-tab-map
          (cons (cons root name)
                (seq-remove (lambda (entry)
                              (or (equal (car entry) root)
                                  (equal (cdr entry) name)))
                            tabspaces-project-tab-map)))))

(defun project-tabspaces--project-for-root (root)
  "Return the project whose exact root is ROOT, if it still exists."
  (when-let* ((root (project-tabspaces--normalize-root root))
              (project (project-current nil root))
              (actual-root (project-tabspaces--normalize-root
                            (project-root project)))
              ((equal root actual-root)))
    project))

(defun project-tabspaces-current-project ()
  "Return the project associated with the current workspace.
Prefer the tab's recorded root over the current buffer's directory."
  (if-let ((root (project-tabspaces--tab-root)))
      (project-tabspaces--project-for-root root)
    (project-current nil)))

;; --- Consult Integration ---

(defun project-tabspaces-consult-project-files-and-buffers ()
  "Find files and buffers strictly within the current project."
  (interactive)
  (if-let* ((pr (project-tabspaces-current-project))
            (root (project-root pr)))
      (let ((project-tabspaces--consult-project pr)
            (vertico-sort-function nil)
            (ivy-sort-functions-alist nil)
            (default-directory root))
        (consult--multi '(project-tabspaces--source-project-open-buffers
                          project-tabspaces--source-project-unopened-files)
                        :prompt "Project File/Buffer: "))
    (user-error "Not in a project!")))

(defun project-tabspaces-consult-tabspaces-and-projects ()
  "Unified Consult interface for Tabspaces and Projects."
  (interactive)
  (let ((vertico-sort-function nil)
        (ivy-sort-functions-alist nil))
    (consult--multi '(project-tabspaces--source-tabspaces
                      project-tabspaces--source-projects)
                    :prompt "Workspace/Project: ")))

(defun project-tabspaces-close-workspace ()
  "Kill local buffers and close the active Tabspace."
  (interactive)
  (let* ((bufs (seq-remove
                (lambda (buffer)
                  (or (member (buffer-name buffer) tabspaces-include-buffers)
                      (member (buffer-name buffer) tabspaces-exclude-buffers)))
                (tabspaces--buffer-list)))
         (tab-name (alist-get 'name (tab-bar--current-tab))))

    (if bufs
        (when (yes-or-no-p (format "Kill %d buffers and close workspace '%s'? " (length bufs) tab-name))
          (save-some-buffers nil (lambda () (memq (current-buffer) bufs)))

          (dolist (buf bufs)
            (when (buffer-live-p buf)
              (kill-buffer buf)))

          (tab-bar-close-tab))

      ;; If there are no buffers, just ask to close the empty tab
      (when (yes-or-no-p (format "Workspace '%s' is empty. Close it? " tab-name))
        (tab-bar-close-tab)))))

(with-eval-after-load 'consult
  (defvar project-tabspaces--source-project-open-buffers
    `(:name     "Project Buffers"
      :narrow   ?b
      :category buffer
      :face     consult-buffer
      :history  buffer-name-history
      :state    ,#'consult--buffer-state
      :default  t
      :items    ,(lambda ()
                   (when-let* ((pr project-tabspaces--consult-project)
                               (pr-buffers (project-buffers pr)))
                     (consult--buffer-query
                      :predicate (lambda (buf) (memq buf pr-buffers))
                      :sort 'visibility
                      :as #'buffer-name)))))

  (defvar project-tabspaces--source-project-unopened-files
    `(:name     "Unopened Project Files"
      :narrow   ?f
      :category file
      :face     consult-file
      ;; Wrap the file state to prevent Emacs from freezing on image previews
      :state    ,(lambda ()
                   (let ((fs (funcall #'consult--file-state)))
                     (lambda (action cand)
                       (if (and (eq action 'preview)
                                (stringp cand)
                                (let ((case-fold-search t))
                                  (string-match-p "\\.\\(png\\|jpe?g\\|gif\\|svg\\|webp\\|tiff?\\|bmp\\|ico\\)\\'" cand)))
                           nil ;; Do nothing if we are previewing an image file
                         (funcall fs action cand)))))
      :action   ,(lambda (f)
                   (when-let ((pr project-tabspaces--consult-project))
                     (find-file (expand-file-name f (project-root pr)))))
      :items    ,(lambda ()
                   (when-let* ((pr project-tabspaces--consult-project)
                               (root (project-root pr)))
                     (let ((all-files (project-files pr))
                           (open-files (make-hash-table :test 'equal)))
                       (dolist (b (project-buffers pr))
                         (when-let ((f (buffer-file-name b)))
                           (puthash (expand-file-name f) t open-files)))
                       (delq nil
                             (mapcar (lambda (f)
                                       (let ((absolute (expand-file-name f root)))
                                         (unless (gethash absolute open-files)
                                           (file-relative-name absolute root))))
                                     all-files)))))))

  (defvar project-tabspaces--source-tabspaces
    `(:name     "Active Workspaces"
      :narrow   ?t
      :category tab
      :face     font-lock-keyword-face
      :action   ,#'tabspaces-switch-or-create-workspace
      :items    ,(lambda ()
                   (mapcar (lambda (tab) (alist-get 'name tab))
                           (tab-bar--tabs-recent)))))

  (defvar project-tabspaces--source-projects
    `(:name     "Projects"
      :narrow   ?p
      :category project
      :face     consult-file
      :action   ,#'project-switch-project
      :items    ,#'project-known-project-roots)))


;; --- Tabspaces Core Integration ---

(defun project-tabspaces--tab-for-root (root)
  "Return the tab associated with ROOT."
  (let ((root (project-tabspaces--normalize-root root)))
    (seq-find (lambda (tab)
                (equal root (project-tabspaces--tab-root tab)))
              (tab-bar-tabs))))

(defun project-tabspaces--inferred-tab-roots (tab)
  "Return the distinct project roots inferred from TAB's buffers."
  (let ((index (seq-position (tab-bar-tabs) tab #'eq))
        roots)
    (when index
      (dolist (buffer (tabspaces--buffer-list nil index))
        (when-let* ((dir (buffer-local-value 'default-directory buffer))
                    (project (project-current nil dir)))
          (push (project-tabspaces--normalize-root (project-root project))
                roots))))
    (delete-dups roots)))

(defun project-tabspaces--legacy-tab-for-project (project)
  "Find an unassociated pre-upgrade tab that clearly belongs to PROJECT."
  (let ((root (project-tabspaces--normalize-root (project-root project)))
        (name (project-name project)))
    (seq-find
     (lambda (tab)
       (and (equal name (alist-get 'name tab))
            (not (project-tabspaces--tab-root tab))
            (equal (project-tabspaces--inferred-tab-roots tab) (list root))))
     (tab-bar-tabs))))

(defun project-tabspaces--unique-tab-name (project)
  "Return an unused, descriptive tab name for PROJECT."
  (let* ((root (project-tabspaces--normalize-root (project-root project)))
         (base (project-name project))
         (parent (file-name-nondirectory
                  (directory-file-name
                   (file-name-directory (directory-file-name root)))))
         (names (mapcar (lambda (tab) (alist-get 'name tab))
                        (tab-bar-tabs)))
         (candidate base)
         (counter 2))
    (when (member candidate names)
      (setq candidate (format "%s (%s)" base parent)))
    (while (member candidate names)
      (setq candidate (format "%s (%s)<%d>" base parent counter)
            counter (1+ counter)))
    candidate))

(defun project-tabspaces-force-tab-on-switch (orig-fun dir &rest args)
  "Select DIR's project tab before running `project-switch-project'."
  (if-let* ((project (project-current nil dir))
            (root (project-root project)))
      (let* ((tab (or (project-tabspaces--tab-for-root root)
                      (project-tabspaces--legacy-tab-for-project project)))
             (name (if tab
                       (alist-get 'name tab)
                     (project-tabspaces--unique-tab-name project)))
             ;; A new tab should not inherit the old tab's selected buffer.
             (tab-bar-new-tab-choice
              (lambda () (get-buffer-create "*scratch*"))))
        (tabspaces-switch-or-create-workspace name)
        (project-tabspaces--set-current-tab-root root)
        (apply orig-fun dir args))
    (apply orig-fun dir args)))


;; --- Minor Mode Definition ---

;;;###autoload
(define-minor-mode project-tabspaces-mode
  "Minor mode to integrate project.el contexts with Tabspaces."
  :global t
  (if project-tabspaces-mode
      (progn
        (advice-add 'project-switch-project :around #'project-tabspaces-force-tab-on-switch)
        ;; Remove the old, unsafe implementation when upgrading in a live Emacs.
        (remove-hook 'project-find-functions 'project-tabspaces-fallback-project))
    (advice-remove 'project-switch-project #'project-tabspaces-force-tab-on-switch)
    (remove-hook 'project-find-functions 'project-tabspaces-fallback-project)))

(provide 'project-tabspaces)
;;; project-tabspaces.el ends here

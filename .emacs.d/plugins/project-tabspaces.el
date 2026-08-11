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

;; --- Consult Integration ---

(defun project-tabspaces--switch-existing-workspace (name)
  "Switch to the existing workspace NAME without creating a new one."
  (when (and (stringp name)
             (seq-find (lambda (tab)
                         (equal name (alist-get 'name tab)))
                       (tab-bar-tabs))
             (not (equal name
                         (alist-get 'name (tab-bar--current-tab)))))
    (tabspaces-switch-or-create-workspace name)))

(defun project-tabspaces--tab-state ()
  "Return a Consult state function that previews existing workspaces."
  (let ((start-tab (alist-get 'name (tab-bar--current-tab))))
    (lambda (action cand)
      (pcase action
        ('preview
         (if (and (stringp cand)
                  (seq-find (lambda (tab)
                              (equal cand (alist-get 'name tab)))
                            (tab-bar-tabs)))
             (project-tabspaces--switch-existing-workspace cand)
           (project-tabspaces--switch-existing-workspace start-tab)))
        ((or 'return 'exit)
         ;; Let the source action perform the final switch from a clean context.
         (project-tabspaces--switch-existing-workspace start-tab))))))

(defun project-tabspaces-consult-project-files-and-buffers ()
  "Find files and buffers strictly within the current project."
  (interactive)
  (if-let* ((pr (project-current nil))
            (root (project-root pr)))
      (let ((vertico-sort-function nil)
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
  "Kill all buffers in the current project and close the active Tabspace."
  (interactive)
  (let* ((proj (project-current))
         ;; Try getting project buffers, fallback to tabspaces local buffers if no project
         (bufs (if proj
                   (project-buffers proj)
                 (when (bound-and-true-p tabspaces--local-tab-buffers)
                   tabspaces--local-tab-buffers)))
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
                   (when-let* ((pr (project-current nil))
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
                   (when-let ((pr (project-current nil)))
                     (find-file (expand-file-name f (project-root pr)))))
      :items    ,(lambda ()
                   (when-let* ((pr (project-current nil))
                               (root (project-root pr)))
                     (let ((all-files (project-files pr))
                           (root-len (length root))
                           (open-files (make-hash-table :test 'equal)))
                       (dolist (b (project-buffers pr))
                         (when-let ((f (buffer-file-name b)))
                           (puthash f t open-files)))
                       (delq nil
                             (mapcar (lambda (f)
                                       (unless (gethash f open-files)
                                         (if (string-prefix-p root f)
                                             (substring f root-len)
                                           (file-relative-name f root))))
                                     all-files)))))))

  (defvar project-tabspaces--source-tabspaces
    `(:name     "Active Workspaces"
      :narrow   ?t
      :category tab
      :face     font-lock-keyword-face
      :state    ,#'project-tabspaces--tab-state
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

(defun project-tabspaces-force-tab-on-switch (orig-fun dir &rest args)
  "Create/switch to tabspace BEFORE running `project-switch-project'."
  (let* ((proj (project-current nil dir))
         (name (if proj (project-name proj) tabspaces-default-tab))
         (tab-exists (seq-find (lambda (tab) (equal name (alist-get 'name tab)))
                               (tab-bar-tabs))))
    (tabspaces-switch-or-create-workspace name)
    (unless tab-exists
      (apply orig-fun dir args))))

(defvar project-tabspaces--finding-fallback nil
  "Prevent infinite recursion in `project-tabspaces-fallback-project'.")

(defun project-tabspaces-fallback-project (_dir)
  "Fallback to current tabspace's project if the buffer has no project.
Appended to `project-find-functions'."
  (unless project-tabspaces--finding-fallback
    (let ((project-tabspaces--finding-fallback t))
      (when (and (bound-and-true-p tabspaces-mode)
                 (bound-and-true-p tab-bar-mode))
        (when-let ((tab-name (alist-get 'name (tab-bar--current-tab))))
          (catch 'found
            (dolist (root (project-known-project-roots))
              ;; Find the project root whose name matches our current tab name
              (when-let ((proj (project-current nil root)))
                (when (equal (project-name proj) tab-name)
                  (throw 'found proj))))))))))


;; --- Minor Mode Definition ---

;;;###autoload
(define-minor-mode project-tabspaces-mode
  "Minor mode to integrate project.el contexts with Tabspaces."
  :global t
  (if project-tabspaces-mode
      (progn
        (advice-add 'project-switch-project :around #'project-tabspaces-force-tab-on-switch)
        (add-hook 'project-find-functions #'project-tabspaces-fallback-project t))
    (advice-remove 'project-switch-project #'project-tabspaces-force-tab-on-switch)
    (remove-hook 'project-find-functions #'project-tabspaces-fallback-project)))

(provide 'project-tabspaces)
;;; project-tabspaces.el ends here

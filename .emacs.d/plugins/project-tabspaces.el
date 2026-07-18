;;; project-tabspaces.el --- Tabspaces and project.el integration -*- lexical-binding: t; -*-

;; Author: You
;; Description: Seamlessly integrate project.el commands with tabspaces.

(require 'project)
(require 'consult)
(require 'tabspaces)

(defgroup project-tabspaces nil
  "Integration between project.el and tabspaces."
  :group 'tabspaces)

;; --- Consult Integration ---

(defun project-tabspaces-consult-project-files-and-buffers ()
  "Find files and buffers strictly within the current project."
  (interactive)
  (if (project-current nil)
      (let ((vertico-sort-function nil)
            (ivy-sort-functions-alist nil))
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

(with-eval-after-load 'consult
  (defvar project-tabspaces--source-project-open-buffers
    `(:name     "Project Buffers"
      :narrow   ?b
      :category buffer
      :face     consult-buffer
      :sort     nil
      :action   ,(lambda (cand)
                   (let ((actual-buffer (get-text-property 0 'consult--candidate cand)))
                     (switch-to-buffer (or actual-buffer cand))))
      :items    ,(lambda ()
                   (when-let* ((pr (project-current nil))
                               (root (project-root pr)))
                     (mapcar (lambda (b)
                               (let ((file (buffer-file-name b))
                                     (name (buffer-name b)))
                                 (if file
                                     (propertize (file-relative-name file root) 'consult--candidate b)
                                   (propertize name 'consult--candidate b))))
                             (consult--buffer-sort-visibility
                              (seq-filter (lambda (b)
                                            (not (string-prefix-p " " (buffer-name b))))
                                          (project-buffers pr))))))))

  (defvar project-tabspaces--source-project-unopened-files
    `(:name     "Unopened Project Files"
      :narrow   ?f
      :category file
      :face     consult-file
      :action   ,(lambda (f)
                   (when-let ((pr (project-current nil)))
                     (find-file (expand-file-name f (project-root pr)))))
      :items    ,(lambda ()
                   (when-let* ((pr (project-current nil))
                               (root (project-root pr)))
                     (let ((all-files (project-files pr))
                           (open-files (delq nil (mapcar #'buffer-file-name (project-buffers pr)))))
                       (delq nil
                             (mapcar (lambda (f)
                                       (unless (member f open-files)
                                         (file-relative-name f root)))
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

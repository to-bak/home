;;; project-tabspaces.el --- Tabspaces and project.el integration -*- lexical-binding: t; -*-

;; Author: You
;; Description: Seamlessly route buffers to project-specific Tabspaces.

(require 'project)
(require 'consult)
(require 'tabspaces)

;; --- Customization Variables ---

(defgroup project-tabspaces nil
  "Integration between project.el and tabspaces."
  :group 'tabspaces)

(defcustom project-tabspaces-wildcard-exemptions '("*Org Agenda*")
  "List of buffers starting with '*' that SHOULD trigger tabspace routing.
Normally, temporary buffers (starting with * or space) are ignored by the router
so they don't force workspace switches. Add buffers here to bypass that rule."
  :type '(repeat string)
  :group 'project-tabspaces)

;; --- Consult Integration ---

(defun project-tabspaces-consult-project-files-and-buffers ()
  "Find files and buffers strictly within the current project."
  (interactive)
  (require 'consult) ;; <-- ADDED HERE
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
  (require 'consult) ;; <-- ADDED HERE
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
                                     all-files))))))) ;; <--- FIXED: Removed the stray 8th parenthesis here

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

;; --- The Router Engine ---

;; --- The Router Engine ---

(defvar project-tabspaces--inhibited nil
  "Internal flag to prevent infinite loops during workspace switching.")

(defun project-tabspaces-auto-router (orig-fun buffer-or-name &rest args)
  "Proactively switch to the correct project tabspace BEFORE displaying a buffer."
  ;; 1. Bail out immediately if we are already switching tabs or if tab-bar isn't ready
  (if (or project-tabspaces--inhibited
          (not tabspaces-mode)
          (not (bound-and-true-p tab-bar-mode)))
      (apply orig-fun buffer-or-name args)

    ;; 2. Otherwise, check the buffer
    (let* ((buffer (get-buffer-create buffer-or-name))
           (buf-name (buffer-name buffer)))

      (unless (or (string-prefix-p " " buf-name)
                  (member buf-name tabspaces-include-buffers)
                  (and (string-prefix-p "*" buf-name)
                       (not (member buf-name project-tabspaces-wildcard-exemptions))))

        (let* ((proj (with-current-buffer buffer (project-current)))
               (target-tab (if proj (project-name proj) tabspaces-default-tab))
               (current-tab (alist-get 'name (tab-bar--current-tab))))

          ;; 3. Switch tab spaces using the INHIBIT flag to prevent loops
          (when (and target-tab current-tab (not (equal current-tab target-tab)))
            (let ((project-tabspaces--inhibited t))
              (tabspaces-switch-or-create-workspace target-tab))))))

    ;; 4. Pass control back to Emacs
    (apply orig-fun buffer-or-name args)))

(defun project-tabspaces-force-tab-on-switch (orig-fun dir &rest args)
  "Generic advice: Create/switch to tabspace BEFORE running `project-switch-project'."
  (let* ((proj (project-current nil dir))
         (name (if proj (project-name proj) tabspaces-default-tab))
         (tab-exists (seq-find (lambda (tab) (equal name (alist-get 'name tab)))
                               (tab-bar-tabs))))

    ;; Use the INHIBIT flag here too
    (let ((project-tabspaces--inhibited t))
      (tabspaces-switch-or-create-workspace name))

    (unless tab-exists
      (apply orig-fun dir args))))

;; --- Minor Mode Definition ---

;;;###autoload
(define-minor-mode project-tabspaces-mode
  "Minor mode to seamlessly route buffers to project-specific Tabspaces."
  :global t
  (if project-tabspaces-mode
      (progn
        (advice-add 'switch-to-buffer :around #'project-tabspaces-auto-router)
        (advice-add 'display-buffer :around #'project-tabspaces-auto-router)
        (advice-add 'project-switch-project :around #'project-tabspaces-force-tab-on-switch))
    (advice-remove 'switch-to-buffer #'project-tabspaces-auto-router)
    (advice-remove 'display-buffer #'project-tabspaces-auto-router)
    (advice-remove 'project-switch-project #'project-tabspaces-force-tab-on-switch)))

(provide 'project-tabspaces)
;;; project-tabspaces.el ends here

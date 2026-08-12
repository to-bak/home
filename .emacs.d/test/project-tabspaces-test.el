;;; project-tabspaces-test.el --- Tests for project-tabspaces -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'project-tabspaces)

(cl-defmethod project-root ((project (head project-tabspaces-test)))
  (plist-get (cdr project) :root))

(cl-defmethod project-name ((project (head project-tabspaces-test)))
  (plist-get (cdr project) :name))

(cl-defmethod project-buffers ((project (head project-tabspaces-test)))
  (plist-get (cdr project) :buffers))

(cl-defmethod project-files ((project (head project-tabspaces-test))
                             &optional _dirs)
  (plist-get (cdr project) :files))

(defun project-tabspaces-test--project (name root &rest properties)
  "Create a test project named NAME at ROOT with PROPERTIES."
  (append (list 'project-tabspaces-test :name name :root root) properties))

(defmacro project-tabspaces-test--with-clean-tabs (&rest body)
  "Run BODY with isolated tab and project-map state."
  (declare (indent 0) (debug t))
  `(let ((saved-tabs (frame-parameter nil 'tabs))
         (saved-map tabspaces-project-tab-map))
     (unwind-protect
         (progn
           (set-frame-parameter nil 'tabs nil)
           (setq tabspaces-project-tab-map nil)
           (tab-bar-tabs)
           ,@body)
       (setq tabspaces-project-tab-map saved-map)
       (set-frame-parameter nil 'tabs saved-tabs))))

(ert-deftest project-tabspaces-normalizes-roots ()
  (should (equal (project-tabspaces--normalize-root "/tmp/example")
                 "/tmp/example/")))

(ert-deftest project-tabspaces-records-root-on-tab-and-session-map ()
  (project-tabspaces-test--with-clean-tabs
    (tab-bar-rename-tab "example")
    (project-tabspaces--set-current-tab-root "/tmp/example")
    (should (equal (project-tabspaces--tab-root) "/tmp/example/"))
    (should (equal tabspaces-project-tab-map
                   '(("/tmp/example/" . "example"))))
    ;; Updating a tab must remove both stale roots and stale name mappings.
    (project-tabspaces--set-current-tab-root "/tmp/replacement")
    (should (equal tabspaces-project-tab-map
                   '(("/tmp/replacement/" . "example"))))))

(ert-deftest project-tabspaces-restores-root-from-session-map ()
  (project-tabspaces-test--with-clean-tabs
    (tab-bar-rename-tab "restored")
    (setq tabspaces-project-tab-map '(("/tmp/restored" . "restored")))
    (should (equal (project-tabspaces--tab-root) "/tmp/restored/"))))

(ert-deftest project-tabspaces-current-project-prefers-tab-root ()
  (let ((project-a (project-tabspaces-test--project "a" "/tmp/a/"))
        (project-b (project-tabspaces-test--project "b" "/tmp/b/")))
    (cl-letf (((symbol-function 'project-tabspaces--tab-root)
               (lambda (&optional _tab) "/tmp/a/"))
              ((symbol-function 'project-current)
               (lambda (_prompt directory)
                 (if (equal directory "/tmp/a/") project-a project-b))))
      (should (eq (project-tabspaces-current-project) project-a)))))

(ert-deftest project-tabspaces-current-project-rejects-stale-root ()
  (let ((project-b (project-tabspaces-test--project "b" "/tmp/b/")))
    (cl-letf (((symbol-function 'project-tabspaces--tab-root)
               (lambda (&optional _tab) "/tmp/missing/"))
              ((symbol-function 'project-current)
               (lambda (&rest _) project-b)))
      ;; Never silently substitute the current buffer's unrelated project.
      (should-not (project-tabspaces-current-project)))))

(ert-deftest project-tabspaces-switch-keeps-same-named-projects-distinct ()
  (project-tabspaces-test--with-clean-tabs
    (let ((project-a (project-tabspaces-test--project
                      "shared" "/tmp/parent-a/shared/"))
          (project-b (project-tabspaces-test--project
                      "shared" "/tmp/parent-b/shared/"))
          calls)
      (cl-letf (((symbol-function 'project-current)
                 (lambda (_prompt directory)
                   (if (string-prefix-p "/tmp/parent-a/" directory)
                       project-a
                     project-b)))
                ((symbol-function 'project-tabspaces--legacy-tab-for-project)
                 (lambda (_project) nil)))
        (dolist (directory '("/tmp/parent-a/shared/"
                             "/tmp/parent-b/shared/"
                             "/tmp/parent-a/shared/"))
          (project-tabspaces-force-tab-on-switch
           (lambda (dir &rest _) (push dir calls)) directory))
        (should (= (length calls) 3))
        ;; Initial non-project tab plus exactly one tab for each project.
        (should (= (length (tab-bar-tabs)) 3))
        (should (equal (project-tabspaces--tab-root)
                       "/tmp/parent-a/shared/"))
        (should (equal (sort (mapcar #'car tabspaces-project-tab-map)
                             #'string<)
                       '("/tmp/parent-a/shared/"
                         "/tmp/parent-b/shared/")))))))

(ert-deftest project-tabspaces-switch-without-project-only-runs-original ()
  (let (called)
    (cl-letf (((symbol-function 'project-current) (lambda (&rest _) nil))
              ((symbol-function 'tabspaces-switch-or-create-workspace)
               (lambda (&rest _) (ert-fail "Workspace switch was unexpected"))))
      (project-tabspaces-force-tab-on-switch
       (lambda (dir &rest args) (setq called (cons dir args)))
       "/tmp/not-a-project/" :argument)
      (should (equal called '("/tmp/not-a-project/" :argument))))))

(ert-deftest project-tabspaces-legacy-migration-requires-an-exact-root ()
  (let* ((project (project-tabspaces-test--project "legacy" "/tmp/legacy/"))
         (tab '(tab (name . "legacy"))))
    (cl-letf (((symbol-function 'tab-bar-tabs) (lambda (&optional _) (list tab)))
              ((symbol-function 'project-tabspaces--tab-root)
               (lambda (&optional _) nil))
              ((symbol-function 'project-tabspaces--inferred-tab-roots)
               (lambda (_) '("/tmp/legacy/"))))
      (should (eq (project-tabspaces--legacy-tab-for-project project) tab)))
    (cl-letf (((symbol-function 'tab-bar-tabs) (lambda (&optional _) (list tab)))
              ((symbol-function 'project-tabspaces--tab-root)
               (lambda (&optional _) nil))
              ((symbol-function 'project-tabspaces--inferred-tab-roots)
               (lambda (_) '("/tmp/other/"))))
      (should-not (project-tabspaces--legacy-tab-for-project project)))))

(ert-deftest project-tabspaces-consult-captures-one-project ()
  (let* ((project (project-tabspaces-test--project "consult" "/tmp/consult/"))
         observed-project
         observed-directory
         observed-sources)
    (cl-letf (((symbol-function 'project-tabspaces-current-project)
               (lambda () project))
              ((symbol-function 'consult--multi)
               (lambda (sources &rest _)
                 (setq observed-project project-tabspaces--consult-project
                       observed-directory default-directory
                       observed-sources sources))))
      (project-tabspaces-consult-project-files-and-buffers)
      (should (eq observed-project project))
      (should (equal observed-directory "/tmp/consult/"))
      (should (equal observed-sources
                     '(project-tabspaces--source-project-open-buffers
                       project-tabspaces--source-project-unopened-files))))))

(ert-deftest project-tabspaces-consult-rejects-non-project-workspace ()
  (cl-letf (((symbol-function 'project-tabspaces-current-project)
             (lambda () nil)))
    (should-error (project-tabspaces-consult-project-files-and-buffers)
                  :type 'user-error)))

(ert-deftest project-tabspaces-unopened-files-exclude-open-buffers ()
  (let ((buffer (generate-new-buffer " *project-tabspaces-open*")))
    (unwind-protect
        (progn
          (with-current-buffer buffer
            (setq buffer-file-name "/tmp/files/open.el"))
          (let* ((project (project-tabspaces-test--project
                           "files" "/tmp/files/"
                           :buffers (list buffer)
                           :files '("open.el" "/tmp/files/closed.el")))
                 (project-tabspaces--consult-project project)
                 (items (plist-get
                         project-tabspaces--source-project-unopened-files
                         :items)))
            (should (equal (funcall items) '("closed.el")))))
      (kill-buffer buffer))))

(ert-deftest project-tabspaces-close-workspace-kills-only-local-user-buffers ()
  (let ((user-buffer (generate-new-buffer " *project-tabspaces-user*"))
        (included-buffer (generate-new-buffer " *project-tabspaces-included*"))
        killed
        closed)
    (unwind-protect
        (let ((tabspaces-include-buffers (list (buffer-name included-buffer)))
              (tabspaces-exclude-buffers nil))
          (cl-letf (((symbol-function 'tabspaces--buffer-list)
                     (lambda (&rest _) (list user-buffer included-buffer)))
                    ((symbol-function 'tab-bar--current-tab)
                     (lambda (&rest _) '(current-tab (name . "test"))))
                    ((symbol-function 'yes-or-no-p) (lambda (&rest _) t))
                    ((symbol-function 'save-some-buffers) (lambda (&rest _) nil))
                    ((symbol-function 'kill-buffer)
                     (lambda (buffer) (push buffer killed)))
                    ((symbol-function 'tab-bar-close-tab)
                     (lambda (&rest _) (setq closed t))))
            (project-tabspaces-close-workspace)
            (should (equal killed (list user-buffer)))
            (should closed)))
      (when (buffer-live-p user-buffer) (kill-buffer user-buffer))
      (when (buffer-live-p included-buffer) (kill-buffer included-buffer)))))

(ert-deftest project-tabspaces-mode-does-not-register-a-project-finder ()
  (let ((project-tabspaces-mode nil))
    (unwind-protect
        (progn
          (project-tabspaces-mode 1)
          (should-not (memq 'project-tabspaces-fallback-project
                            project-find-functions))
          (should (advice-member-p #'project-tabspaces-force-tab-on-switch
                                   'project-switch-project)))
      (project-tabspaces-mode -1))))

(provide 'project-tabspaces-test)
;;; project-tabspaces-test.el ends here

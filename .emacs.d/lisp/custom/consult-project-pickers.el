;;; consult-project-pickers.el --- Project buffers and files -*- lexical-binding: t; -*-

;;; Commentary:

;; Inspired by consult-project-extra's combined buffer/file picker.
;; Project buffers come first, most recently visited first, followed by all
;; project files.  Put the current buffer last so RET switches to the previous
;; buffer.  Consult preserves this order even while filtering.

;;; Code:

(require 'project)
(require 'consult)
(require 'consult-project-pickers-preview)

(defun consult-project-pickers--buffers ()
  "Return project buffer pairs in visit order, with the current buffer last."
  (let* ((buffers (consult--buffer-query :directory (consult--project-root)
                                         :buffer-list #'buffer-list
                                         :sort nil))
         (current (memq (current-buffer) buffers)))
    (when current
      (setq buffers (append (delq (current-buffer) buffers)
                            (list (current-buffer)))))
    (mapcar #'consult--buffer-pair buffers)))

(defun consult-project-pickers--files ()
  "Return project-relative display names paired with absolute file names."
  (let* ((root (consult--project-root))
         (project (project-current nil root)))
    (mapcar (lambda (file)
              (let ((absolute (expand-file-name file root)))
                (cons (file-relative-name absolute root) absolute)))
            (project-files project))))

(defun consult-project-pickers--new-file (file)
  "Visit a new FILE relative to the project root."
  (consult--file-action (expand-file-name file (consult--project-root))))

(defvar consult-project-pickers--source-buffer
  (let ((source (copy-sequence consult-source-project-buffer)))
    (plist-put source :hidden nil)
    (plist-put source :default t)
    (plist-put source :items #'consult-project-pickers--buffers)
    source)
  "Project buffer source, most recent first with the current buffer last.")

(defvar consult-project-pickers--source-file
  '(:name "Project File"
    :narrow (?f . "File")
    :category file
    :face consult-file
    :history file-name-history
    :action consult--file-action
    :new consult-project-pickers--new-file
    :state consult-project-pickers-preview-state
    :preview-key any
    :items consult-project-pickers--files)
  "All project files, with immediate automatic previews.")

;;;###autoload
(defun consult-project-pickers-find (&optional other-window)
  "Select a project buffer or file, with most recently visited buffers first.
The current buffer comes last, so repeated selection toggles buffers.
Prompt for a project when called outside one.  Narrow to buffers with b
or files with f using `consult-narrow-key'.  Files preview immediately.
With prefix argument OTHER-WINDOW, open the selection in another window."
  (interactive "P")
  (let ((consult--buffer-display
         (if other-window #'switch-to-buffer-other-window #'switch-to-buffer)))
    (consult--with-project
      (consult--multi '(consult-project-pickers--source-buffer consult-project-pickers--source-file)
                      :sort nil
                      :require-match nil))))

(provide 'consult-project-pickers)
;;; consult-project-pickers.el ends here

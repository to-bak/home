;;; consult-project-pickers-preview.el --- Lightweight file previews -*- lexical-binding: t; -*-

;;; Commentary:

;; Detection and placeholder design follow Telescope's previewers:
;; https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/previewers/buffer_previewer.lua
;; https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/previewers/utils.lua
;; Recognized text modes bypass MIME detection.  Other files are classified
;; using `file --mime-type`, before any major mode or renderer can run.
;; Emacs recognizes image/PDF modes too, so only text/prog modes bypass MIME.
;; Consult owns temporary buffers, exclusions, caching and cleanup.

;;; Code:

(require 'consult)

(defun consult-project-pickers-preview--text-mode-p (file)
  "Return non-nil when FILE has a known text or programming mode.
Inspect mode metadata without loading or executing the mode."
  (let ((mode (assoc-default file auto-mode-alist #'string-match-p)))
    (and (symbolp mode)
         (provided-mode-derived-p mode '(text-mode prog-mode)))))

(defun consult-project-pickers-preview--mime-type (file)
  "Return FILE's MIME type, or nil if detection is unavailable or fails."
  (when-let* ((program (executable-find "file")))
    (condition-case nil
        (with-temp-buffer
          (when (eq 0 (call-process program nil '(t nil) nil
                                   "--brief" "--mime-type" "--dereference" "-E"
                                   "--" (expand-file-name file)))
            (string-trim (buffer-string))))
      (file-error nil))))

(defun consult-project-pickers-preview--binary-mime-p (mime)
  "Classify MIME using Telescope's binary MIME rule.
Text and inode types, plus JSON and JavaScript subtypes, are textual."
  (let ((parts (split-string mime "/")))
    (not (or (member (car parts) '("text" "inode"))
             (member (cadr parts) '("json" "javascript"))))))

(defun consult-project-pickers-preview--file-kind (file)
  "Classify FILE as `text', `binary' or `unknown' without opening it."
  (cond
   ((consult-project-pickers-preview--text-mode-p file) 'text)
   ((when-let* ((mime (consult-project-pickers-preview--mime-type file)))
      (if (consult-project-pickers-preview--binary-mime-p mime) 'binary 'text)))
   (t 'unknown)))

(defun consult-project-pickers-preview--placeholder (message)
  "Create a read-only patterned buffer with a centered MESSAGE."
  (let* ((window (consult--original-window))
         (width (max 1 (window-body-width window)))
         (height (max 1 (window-body-height window)))
         (label (truncate-string-to-width (concat "  " message "  ") width))
         (padding (/ (- width (string-width label)) 2))
         (pattern (propertize (make-string width ?╱) 'face 'shadow))
         (buffer (generate-new-buffer " *file-preview*")))
    (with-current-buffer buffer
      (dotimes (row height)
        (insert
         (if (= row (/ height 2))
             (concat (substring pattern 0 padding)
                     (propertize label 'face 'font-lock-doc-face)
                     (substring pattern (+ padding (string-width label))))
           pattern)
         "\n"))
      (goto-char (point-min))
      (setq-local truncate-lines t
                  cursor-type nil
                  buffer-read-only t)
      (set-buffer-modified-p nil))
    buffer))

(defun consult-project-pickers-preview--open (open file)
  "Use OPEN for text FILE, otherwise return a lightweight placeholder."
  (pcase (consult-project-pickers-preview--file-kind file)
    ('text (funcall open file))
    ('binary (consult-project-pickers-preview--placeholder
              "Binary cannot be previewed"))
    (_ (consult-project-pickers-preview--placeholder
        "File type unavailable"))))

(defun consult-project-pickers-preview-state ()
  "Create a Consult file preview state with MIME-based binary placeholders."
  (let ((state (consult--file-preview))
        (open (symbol-function 'consult--find-file-temporarily)))
    (lambda (action candidate)
      ;; Replace only the temporary opener during this callback.  Keeping
      ;; Consult's file state preserves its cache, exclusions and cleanup;
      ;; the final file-opening action continues to use the normal opener.
      (cl-letf (((symbol-function 'consult--find-file-temporarily)
                 (lambda (file)
                   (consult-project-pickers-preview--open open file))))
        (funcall state action candidate)))))

(provide 'consult-project-pickers-preview)
;;; consult-project-pickers-preview.el ends here

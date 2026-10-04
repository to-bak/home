;;; org-dispatch.el --- Dispatch a prepared Org unit -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1") (transient "0.7.0"))
;;; Commentary:
;; C-c m reads the containing top-level subtree. Menu overrides are ephemeral.
;; Outputs receive a plist with :title, :text, :directory, :arguments and
;; optional :model. Clipboard is the only built-in output.
;;; Code:
(require 'org)
(require 'org-element)
(require 'subr-x)
(require 'transient)

(defgroup org-dispatch nil "Dispatch prepared Org prompts." :group 'org)
(defcustom org-dispatch-default-model nil
  "Model used when MODEL metadata is absent; nil lets the receiver decide."
  :type '(choice (const nil) string))
(defcustom org-dispatch-default-directory nil
  "Workspace used when DIRECTORY is absent; nil uses the source directory."
  :type '(choice (const nil) directory))
(defcustom org-dispatch-default-arguments ""
  "CLI argument text used when CLI_ARGS is absent."
  :type 'string)

(defun org-dispatch-copy (request)
  "Copy REQUEST's text using Emacs's clipboard integration."
  (kill-new (plist-get request :text))
  (message "Prompt copied"))

(defvar org-dispatch-outputs '((clipboard . org-dispatch-copy))
  "Alist of output names and functions accepting one dispatch request plist.
Adapters should signal errors on failure. They own any delivery behavior.")

(defun org-dispatch--root ()
  "Move to the containing top-level heading, with the buffer widened."
  (unless (derived-mode-p 'org-mode) (user-error "Dispatch from an Org heading"))
  (widen)
  (when (org-before-first-heading-p) (user-error "Place point inside an Org unit"))
  (org-back-to-heading t)
  (while (org-up-heading-safe)))

(defun org-dispatch--read ()
  "Read a fresh source marker and its initial dispatch parameters."
  (save-excursion
    (save-restriction
      (org-dispatch--root)
      (list :marker (copy-marker (point) t) :output 'clipboard
            :parameters
            (list :model (or (org-entry-get nil "MODEL" t) org-dispatch-default-model)
                  :directory (file-name-as-directory
                              (expand-file-name
                               (or (org-entry-get nil "DIRECTORY" t)
                                   org-dispatch-default-directory default-directory)))
                  :arguments (or (org-entry-get nil "CLI_ARGS" t)
                                 org-dispatch-default-arguments))))))

(defun org-dispatch--scope ()
  "Return the active dispatch menu's scope."
  (or (transient-scope 'org-dispatch) (user-error "Open org-dispatch first")))

(defun org-dispatch--text ()
  "Read the current subtree, omitting drawers, planning and headline metadata."
  (let ((begin (point))
        (end (save-excursion (org-end-of-subtree t t))) edits)
    (save-restriction
      (narrow-to-region begin end)
      (org-element-map (org-element-parse-buffer) '(headline drawer property-drawer planning)
        (lambda (element)
          (let ((start (org-element-property :begin element)))
            (if (eq (org-element-type element) 'headline)
                (save-excursion
                  (goto-char start)
                  (push (list (- start begin) (- (line-end-position) begin)
                              (concat (make-string (org-outline-level) ?*) " "
                                      (org-get-heading t t t t))) edits))
              (push (list (- start begin) (- (org-element-property :end element) begin) "") edits)))))
      (let ((text (buffer-substring-no-properties begin end)))
        (with-temp-buffer
          (insert text)
          (dolist (edit (sort edits (lambda (a b) (> (car a) (car b)))))
            (goto-char (1+ (car edit)))
            (delete-region (point) (1+ (cadr edit)))
            (insert (nth 2 edit)))
          (string-trim (buffer-string)))))))

(defun org-dispatch-data (&optional scope)
  "Build a request from SCOPE, or the current Org unit outside a dispatch menu.
Source text is read live. The request contains no marker or absent model key."
  (let* ((scope (or scope (org-dispatch--read)))
         (marker (plist-get scope :marker))
         (parameters (plist-get scope :parameters)))
    (unless (and (markerp marker) (marker-buffer marker))
      (user-error "Source buffer was closed"))
    (org-with-point-at marker
      (save-restriction
        (org-dispatch--root)
        (let* ((directory (plist-get parameters :directory))
               (model (plist-get parameters :model))
               (request (list :title (org-get-heading t t t t) :directory directory
                              :arguments (split-string-and-unquote (plist-get parameters :arguments))
                              :text (concat "Workspace: " directory "\n\n" (org-dispatch--text)))))
          (if (and model (not (string-empty-p model)))
              (append request (list :model model)) request))))))

(defun org-dispatch--label (key title)
  "Describe parameter KEY with TITLE in the menu."
  (let ((value (plist-get (plist-get (org-dispatch--scope) :parameters) key)))
    (concat title " "
            (propertize (if (or (null value) (equal value "")) "default"
                          (truncate-string-to-width value 60 nil nil "…"))
                        'face 'transient-value))))

(defun org-dispatch-set-model ()
  "Override the model for this invocation; empty input leaves it unspecified."
  (interactive)
  (let ((parameters (plist-get (org-dispatch--scope) :parameters)))
    (setf (plist-get parameters :model)
          (string-trim (read-string "Model (empty = receiver default): " (plist-get parameters :model))))))

(defun org-dispatch-set-directory ()
  "Override the workspace for this invocation."
  (interactive)
  (let ((parameters (plist-get (org-dispatch--scope) :parameters)))
    (setf (plist-get parameters :directory)
          (file-name-as-directory
           (expand-file-name (read-directory-name "Workspace: " (plist-get parameters :directory)))))))

(defun org-dispatch-set-arguments ()
  "Override argument text for this invocation; quote arguments containing spaces."
  (interactive)
  (let ((parameters (plist-get (org-dispatch--scope) :parameters)))
    (setf (plist-get parameters :arguments)
          (read-string "CLI arguments: " (plist-get parameters :arguments)))))

(defun org-dispatch-set-output ()
  "Select a registered output for this invocation."
  (interactive)
  (let ((scope (org-dispatch--scope)))
    (setf (plist-get scope :output)
          (intern (completing-read "Output: " org-dispatch-outputs nil t)))))

(defun org-dispatch-send ()
  "Build the request and invoke the selected output adapter."
  (interactive)
  (let* ((scope (org-dispatch--scope))
         (output (plist-get scope :output))
         (function (or (alist-get output org-dispatch-outputs)
                       (user-error "Unknown output: %s" output))))
    (funcall function (org-dispatch-data scope))))

(defun org-dispatch-copy-current ()
  "Copy this invocation's prompt regardless of the selected output."
  (interactive)
  (org-dispatch-copy (org-dispatch-data (org-dispatch--scope))))

(defun org-dispatch-copy-preview ()
  "Copy exactly the displayed preview, without rereading the source."
  (interactive)
  (kill-new (buffer-substring-no-properties (point-min) (point-max)))
  (message "Preview copied"))

(define-derived-mode org-dispatch-preview-mode special-mode "Dispatch"
  "Read a frozen prompt; C-c C-c copies it and q closes the preview.")
(define-key org-dispatch-preview-mode-map (kbd "C-c C-c") #'org-dispatch-copy-preview)

(defun org-dispatch-preview ()
  "Preview this invocation's prepared prompt without changing the source."
  (interactive)
  (let* ((request (org-dispatch-data (org-dispatch--scope)))
         (buffer (generate-new-buffer "*Org dispatch*")))
    (with-current-buffer buffer
      (insert (plist-get request :text))
      (goto-char (point-min))
      (org-dispatch-preview-mode)
      (setq header-line-format " C-c C-c: copy · q: close"))
    (pop-to-buffer buffer)))

;;;###autoload
(transient-define-prefix org-dispatch ()
  "Dispatch the full top-level Org unit containing point."
  ["Request Parameters"
   ("-m" (lambda () (org-dispatch--label :model "Model")) org-dispatch-set-model :transient t)
   ("-d" (lambda () (org-dispatch--label :directory "Workspace")) org-dispatch-set-directory :transient t)
   ("-A" (lambda () (org-dispatch--label :arguments "CLI arguments")) org-dispatch-set-arguments :transient t)
   ("-o" (lambda () (format "Output %s" (plist-get (org-dispatch--scope) :output)))
    org-dispatch-set-output :transient t)]
  [("v" "Preview" org-dispatch-preview)
   ("w" "Copy" org-dispatch-copy-current)
   ("RET" "Dispatch" org-dispatch-send)
   ("q" "Cancel" transient-quit-one)]
  (interactive)
  (transient-setup 'org-dispatch nil nil :scope (org-dispatch--read)))

(provide 'org-dispatch)
;;; org-dispatch.el ends here

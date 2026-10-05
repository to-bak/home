;;; org-dispatch-codex.el --- Codex output via Ghostel -*- lexical-binding: t; -*-
;;; Commentary:
;; Register a Codex output for prepared Org prompts.  Each dispatch starts
;; a fresh interactive terminal; argv is passed directly without a shell.
;; C-c m, -o, codex, RET.  DIRECTORY, MODEL and CLI_ARGS (or menu overrides)
;; supply the settings.  An absent model uses Codex's configured default.
;;; Code:
(require 'org-dispatch)
(declare-function ghostel-exec "ghostel" (buffer program &optional args identity))

(defcustom org-dispatch-codex-program "codex"
  "Codex executable name or absolute path."
  :type 'string
  :group 'org-dispatch)

(defun org-dispatch-codex (request)
  "Start Codex in a new Ghostel terminal using REQUEST's parameters."
  (let* ((default-directory (plist-get request :directory))
         (model (plist-get request :model)))
    (when (file-remote-p default-directory)
      (user-error "Codex output requires a local workspace"))
    (unless (file-directory-p default-directory)
      (user-error "Workspace does not exist: %s" default-directory))
    (let ((program (or (executable-find org-dispatch-codex-program)
                       (user-error "Executable not found: %s" org-dispatch-codex-program)))
          (args (append (plist-get request :arguments)
                        (when model (list "--model" model))
                        (list "--cd" default-directory "--" (plist-get request :text)))))
      (require 'ghostel)
      (let ((buffer (generate-new-buffer
                     (format "*Codex: %s*" (plist-get request :title)))))
        (condition-case err
            (progn
              (with-current-buffer buffer
                (setq default-directory (plist-get request :directory)))
              (pop-to-buffer buffer)
              (ghostel-exec buffer program args)
              buffer)
          ((error quit)
           (when (buffer-live-p buffer) (kill-buffer buffer))
           (signal (car err) (cdr err))))))))

(setf (alist-get 'codex org-dispatch-outputs) #'org-dispatch-codex)
(provide 'org-dispatch-codex)
;;; org-dispatch-codex.el ends here

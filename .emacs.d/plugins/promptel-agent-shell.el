;;; promptel-agent-shell.el --- Agent output for Promptel -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1") (agent-shell "0.75.2"))
;;; Commentary:
;; This adapter knows nothing about Org.  System instructions become labeled
;; user text.  Model metadata is rejected rather than silently discarded.
;;; Code:
(require 'prompt-compose)
(require 'agent-shell)
(require 'map)
(defvar promptel-agent-shell-delivered-functions nil
  "Functions called with shell BUFFER and opaque ROUTING after delivery.
Consumers may associate the buffer with their own task storage.")

(defun promptel-agent-shell-render (capture)
  "Render CAPTURE as a single agent prompt, preserving role labels."
  (let ((model (plist-get capture :model)))
    (when (and model (not (eq model :null)))
      (user-error "Agent output cannot apply model metadata; clear Model in Promptel first")))
  (mapconcat (lambda (message)
               (pcase (plist-get message :role)
                 ("system" (concat "Instructions for this request:\n" (plist-get message :content)))
                 ("user" (plist-get message :content))
                 (_ (user-error "Unsupported message role: %s" (plist-get message :role)))))
             (plist-get capture :messages) "\n\n"))

(defun promptel-agent-shell-output (capture)
  "Deliver frozen CAPTURE to a selected or new agent shell.
Offer insertion for review or immediate submission.  Existing pending input
must be handled first; it is never silently combined with the capture."
  (let* ((text (promptel-agent-shell-render capture))
         (routing (plist-get (plist-get capture :metadata) :routing))
         (choices (cl-loop for buffer in (buffer-list)
                           when (with-current-buffer buffer (derived-mode-p 'agent-shell-mode))
                           collect (cons (format "%s — %s" (buffer-name buffer)
                                                 (buffer-local-value 'default-directory buffer)) buffer)))
         (choice (completing-read "Destination: " (cons "New session" choices) nil t))
         (buffer (cdr (assoc choice choices)))
         (existing buffer)
         (submit (equal (completing-read "Delivery (instructions become prompt text): "
                                        '("Insert for review" "Send now") nil t nil nil "Insert for review")
                        "Send now")))
    (unless buffer
      (let* ((default-directory (file-name-as-directory
                                 (expand-file-name
                                  (or (plist-get routing :directory)
                                      (read-directory-name "Agent working directory: " nil nil t)))))
             (directory default-directory)
             (agent-shell-cwd-function (lambda () directory))
             (agent-shell-session-strategy 'new))
        (unless (file-directory-p directory) (user-error "Directory missing: %s" directory))
        (setq buffer (agent-shell-start :config (agent-shell-select-config :prompt "Agent: ")))
        (with-current-buffer buffer
          (setq-local agent-shell-cwd-function (lambda () directory)))))
    (when existing
     (with-current-buffer buffer
      (when (shell-maker-busy) (user-error "Agent is busy; retry when it is idle"))
      (when-let* ((process (get-buffer-process buffer)))
        (when (< (marker-position (process-mark process)) (point-max))
          (user-error "Agent has pending input; submit or clear it before delivery")))))
    (agent-shell-insert :shell-buffer buffer :text text :submit submit)
    (run-hook-with-args 'promptel-agent-shell-delivered-functions buffer routing)
    (message (if submit "Prompt submitted (or queued for initialization)"
               "Prompt inserted for review (or queued for initialization)"))))

(prompt-compose-register-output 'agent-shell #'promptel-agent-shell-output)
(provide 'promptel-agent-shell)
;;; promptel-agent-shell.el ends here

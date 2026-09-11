;;; everywhere.el --- Edit text anywhere from Emacs  -*- lexical-binding: t; -*-

;;; Commentary:
;; Based on Thanos Apollo's Wayland Emacs Everywhere workflow.  The Sway
;; container that invoked the editor is remembered so focus can be restored
;; before the completed text is pasted.

;;; Code:
(require 'cl-lib)
(require 'json)
(require 'seq)
(require 'subr-x)

(defgroup thanos/type nil
  "Edit text for another Wayland application."
  :group 'external)

(defcustom thanos/type-paste-delay 0.1
  "Seconds to wait after restoring focus before pasting."
  :type 'number
  :group 'thanos/type)

(defvar-local thanos/type--origin-con-id nil
  "Sway container ID that opened the current Everywhere buffer.")

(defun thanos/type--focused-con-id ()
  "Return the focused Sway container ID, or nil when unavailable."
  (with-temp-buffer
    (when (= 0 (call-process "swaymsg" nil t nil "-t" "get_seats" "-r"))
      (goto-char (point-min))
      (condition-case nil
          (let* ((seats (json-parse-buffer :object-type 'alist
                                           :array-type 'list
                                           :null-object nil
                                           :false-object nil))
                 (seat (or (seq-find
                            (lambda (item)
                              (equal (alist-get 'name item) "seat0"))
                            seats)
                           (car seats)))
                 (focus (alist-get 'focus seat)))
            (unless (zerop (or focus 0)) focus))
        (error nil)))))

(defun thanos/type--close ()
  "Close the current Everywhere frame and kill its temporary buffer."
  (let ((frame (selected-frame))
        (buffer (current-buffer)))
    (set-window-dedicated-p (selected-window) nil)
    (delete-frame frame t)
    (when (buffer-live-p buffer)
      (kill-buffer buffer))))

(defun thanos/type--paste (con-id text)
  "Focus Sway container CON-ID and paste TEXT into it."
  (when con-id
    (call-process "swaymsg" nil nil nil (format "[con_id=%s] focus" con-id)))
  (run-with-timer
   thanos/type-paste-delay nil
   (lambda (contents)
     (with-temp-buffer
       (insert contents)
       (call-process-region (point-min) (point-max) "wl-copy" nil nil nil))
     (call-process "wtype" nil nil nil "-M" "ctrl" "v" "-m" "ctrl"))
   text))

(defun thanos/type-finish ()
  "Finish editing and paste the buffer into the originating application."
  (interactive)
  (let ((text (buffer-substring-no-properties (point-min) (point-max)))
        (con-id thanos/type--origin-con-id))
    (thanos/type--close)
    (thanos/type--paste con-id text)))

(defun thanos/type-cancel ()
  "Cancel editing without pasting anything."
  (interactive)
  (thanos/type--close))

(defvar-keymap thanos/type-mode-map
  "C-c C-c" #'thanos/type-finish
  "C-c C-k" #'thanos/type-cancel)

(define-minor-mode thanos/type-mode
  "Minor mode for editing text destined for another application."
  :lighter " Everywhere"
  :keymap thanos/type-mode-map)

;;;###autoload
(defun thanos/type ()
  "Open a temporary Org buffer for typing into another application."
  (interactive)
  (let* ((origin (thanos/type--focused-con-id))
         (buffer (generate-new-buffer "*Emacs Everywhere*"))
         (frame (make-frame '((name . "emacs-float")
                              (title . "emacs-float")
                              (minibuffer . t)
                              (fullscreen . nil)
                              (undecorated . t)
                              (width . 70)
                              (height . 20)))))
    (select-frame-set-input-focus frame)
    (switch-to-buffer buffer)
    (org-mode)
    (flyspell-mode 1)
    (setq-local thanos/type--origin-con-id origin
                header-line-format
                (format " %s to paste, %s to cancel"
                        (propertize "C-c C-c" 'face 'help-key-binding)
                        (propertize "C-c C-k" 'face 'help-key-binding)))
    (thanos/type-mode 1)
    (set-window-dedicated-p (selected-window) t)))

(provide 'everywhere)
;;; everywhere.el ends here

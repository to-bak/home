;;; sway-emacs-popups.el --- Emacs frames for Sway commands  -*- lexical-binding: t; -*-

;;; Commentary:
;; Open WM-triggered Emacs commands on the invoking Sway workspace.  Short
;; interactions close their frame, while capture and agenda own theirs until
;; the user finishes.

;;; Code:
(require 'subr-x)

(defconst obp/sway-popup--floating-roles
  '(launcher capture clipboard)
  "Popup roles that Sway displays as centered floating frames.")

(defun obp/sway-popup--make-frame (role)
  "Create and focus an Emacs frame for ROLE."
  (let* ((buffer (generate-new-buffer (format " *sway-%s*" role)))
         (floating (memq role obp/sway-popup--floating-roles))
         (name (format "emacs-%s" role))
         (frame (make-frame
                 `((name . ,name)
                   (title . ,name)
                   (minibuffer . t)
                   (fullscreen . nil)
                   (undecorated . ,floating)
                   (width . ,(if floating 100 140))
                   (height . ,(if floating 28 45))
                   (obp-sway-popup-role . ,role)
                   (obp-sway-popup-buffer . ,buffer)))))
    (select-frame-set-input-focus frame)
    (with-selected-frame frame
      (switch-to-buffer buffer)
      (fundamental-mode))
    frame))

(defun obp/sway-popup--kill-owned-buffer (frame)
  "Kill the private staging buffer belonging to FRAME."
  (let ((buffer (frame-parameter frame 'obp-sway-popup-buffer)))
    (when (buffer-live-p buffer)
      (dolist (window (get-buffer-window-list buffer nil t))
        (set-window-buffer window (get-buffer-create "*scratch*")))
      (kill-buffer buffer))))

(defun obp/sway-popup--delete-frame (frame)
  "Delete FRAME when it is still live."
  (when (frame-live-p frame)
    (let ((buffer (frame-parameter frame 'obp-sway-popup-buffer)))
      (delete-frame frame t)
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

(defun obp/sway-popup--abort-minibuffer-on-delete (frame)
  "Abort an active minibuffer owned by transient FRAME before it disappears."
  (let ((minibuffer (active-minibuffer-window)))
    (when (and (frame-parameter frame 'obp-sway-popup-role)
               (window-live-p minibuffer)
               (eq (window-frame minibuffer) frame))
      (abort-recursive-edit))))

(add-hook 'delete-frame-functions
          #'obp/sway-popup--abort-minibuffer-on-delete)

(defun obp/sway-popup--promote-frame (frame)
  "Turn transient FRAME into an ordinary tiled Emacs frame."
  (when (frame-live-p frame)
    (obp/sway-popup--kill-owned-buffer frame)
    (modify-frame-parameters
     frame
     '((name . "emacs")
       (title . nil)
       (undecorated . nil)
       (obp-sway-popup-role . nil)
       (obp-sway-popup-buffer . nil)))
    (with-selected-frame frame
      (call-process "swaymsg" nil nil nil "floating disable"))))

(defun obp/sway-popup--capture-active-p ()
  "Return non-nil when the selected window contains an Org capture."
  (with-current-buffer (window-buffer (selected-window))
    (bound-and-true-p org-capture-mode)))

;;;###autoload
(defun obp/sway-universal-launcher ()
  "Open the universal launcher in a frame on the current Sway workspace."
  (interactive)
  (let ((context (selected-frame))
        (frame (obp/sway-popup--make-frame 'launcher))
        disposition)
    (condition-case err
        (progn
          (setq disposition
                (with-selected-frame frame
                  (universal-launcher-popup context)))
          (pcase disposition
            ('keep
             (if (with-selected-frame frame
                   (obp/sway-popup--capture-active-p))
                 (set-frame-parameter frame 'obp-sway-popup-role 'capture)
               (obp/sway-popup--promote-frame frame)))
            ('context
             (obp/sway-popup--delete-frame frame)
             (when (frame-live-p context)
               (select-frame-set-input-focus context)))
            (_ (obp/sway-popup--delete-frame frame))))
      ((error quit)
       (obp/sway-popup--delete-frame frame)
       (signal (car err) (cdr err))))))

(defun obp/sway-popup--run-and-close (role function)
  "Run FUNCTION in a temporary frame for ROLE, then close it."
  (let ((frame (obp/sway-popup--make-frame role)))
    (unwind-protect
        (with-selected-frame frame
          (funcall function))
      (obp/sway-popup--delete-frame frame))))

;;;###autoload
(defun obp/sway-clipboard-manager ()
  "Open the clipboard manager on the current Sway workspace."
  (interactive)
  (obp/sway-popup--run-and-close 'clipboard #'jb/clipboard-manager))

(defun obp/sway-popup--capture (function)
  "Run capture FUNCTION in a frame that closes after finalization."
  (let ((frame (obp/sway-popup--make-frame 'capture)))
    (condition-case err
        (with-selected-frame frame
          (funcall function))
      ((error quit)
       (obp/sway-popup--delete-frame frame)
       (signal (car err) (cdr err))))))

;;;###autoload
(defun obp/sway-org-capture ()
  "Start Org capture on the current Sway workspace."
  (interactive)
  (obp/sway-popup--capture #'org-capture))

;;;###autoload
(defun obp/sway-roam-capture ()
  "Start today's Org-roam capture on the current Sway workspace."
  (interactive)
  (obp/sway-popup--capture #'org-roam-dailies-capture-today))

(defun obp/sway-popup--finish-capture ()
  "Close the selected transient capture frame after finalization."
  (let ((frame (selected-frame)))
    (when (eq (frame-parameter frame 'obp-sway-popup-role) 'capture)
      (run-at-time 0 nil #'obp/sway-popup--delete-frame frame))))

(with-eval-after-load 'org-capture
  (add-hook 'org-capture-after-finalize-hook
            #'obp/sway-popup--finish-capture))

(defvar-keymap obp/sway-agenda-frame-mode-map
  :doc "Keys used by Org Agenda in its dedicated Sway frame."
  "q" #'obp/sway-agenda-quit)

(define-minor-mode obp/sway-agenda-frame-mode
  "Close the dedicated agenda frame when quitting Org Agenda."
  :lighter nil
  :keymap obp/sway-agenda-frame-mode-map)

(defun obp/sway-popup--agenda-mode ()
  "Enable dedicated-frame behavior for an agenda popup."
  (when (eq (frame-parameter nil 'obp-sway-popup-role) 'agenda)
    (obp/sway-agenda-frame-mode 1)))

(with-eval-after-load 'org-agenda
  (add-hook 'org-agenda-mode-hook #'obp/sway-popup--agenda-mode))

(defun obp/sway-agenda-quit ()
  "Quit Org Agenda and close its dedicated frame."
  (interactive)
  (let ((frame (selected-frame)))
    (org-agenda-quit)
    (obp/sway-popup--delete-frame frame)))

;;;###autoload
(defun obp/sway-agenda ()
  "Open the agenda in a dedicated frame on the current Sway workspace."
  (interactive)
  (let ((frame (obp/sway-popup--make-frame 'agenda)))
    (condition-case err
        (with-selected-frame frame
          (obp/org-agenda-fullscreen))
      ((error quit)
       (obp/sway-popup--delete-frame frame)
       (signal (car err) (cdr err))))))

(provide 'sway-emacs-popups)
;;; sway-emacs-popups.el ends here

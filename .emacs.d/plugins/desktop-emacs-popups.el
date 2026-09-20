;;; desktop-emacs-popups.el --- Dedicated desktop frames  -*- lexical-binding: t; -*-

;;; Commentary:
;; Open window-manager-triggered Emacs commands in purpose-built frames.  The
;; universal launcher uses a true minibuffer-only frame; capture commands use
;; ordinary frames whose lifetime follows the command they host.

;;; Code:

(require 'subr-x)
(require 'seq)

(defvar universal-launcher-context-frame)
(defvar vertico-count)
(defvar org-capture-initial)
(defvar org-capture-link-is-already-stored)
(defvar org-store-link-plist)

(declare-function universal-launcher-popup "universal-launcher" (&optional context-frame))
(declare-function org-roam-capture "org-roam" (&optional goto keys))
(declare-function org-roam-dailies-capture-today "org-roam-dailies" (&optional goto keys))

(defconst obp/desktop-popup--capture-roles
  '(capture roam-capture daily-capture)
  "Popup roles that remain live until Org capture finishes.")

(defun obp/desktop-popup--ordinary-frame (role)
  "Create and focus an ordinary dedicated frame for ROLE."
  (let* ((buffer (generate-new-buffer (format " *desktop-%s*" role)))
         (name (format "emacs-%s" role))
         (frame (make-frame
                 `((name . ,name)
                   (title . ,name)
                   (minibuffer . t)
                   (fullscreen . nil)
                   (width . 110)
                   (height . 38)
                   (obp-desktop-popup-role . ,role)
                   (obp-desktop-popup-buffer . ,buffer)))))
    (select-frame-set-input-focus frame)
    (with-selected-frame frame
      (switch-to-buffer buffer)
      (fundamental-mode))
    frame))

(defun obp/desktop-popup--minibuffer-frame ()
  "Create and focus the minibuffer-only universal launcher frame."
  (let ((frame (make-frame
                '((name . "emacs-launcher")
                  (title . "emacs-launcher")
                  (minibuffer . only)
                  (fullscreen . nil)
                  (undecorated . t)
                  (internal-border-width . 18)
                  (left-fringe . 0)
                  (right-fringe . 0)
                  (menu-bar-lines . 0)
                  (tool-bar-lines . 0)
                  (vertical-scroll-bars . nil)
                  (width . 110)
                  (height . 12)
                  (unsplittable . t)
                  (obp-desktop-popup-role . launcher)))))
    (select-frame-set-input-focus frame)
    frame))

(defun obp/desktop-popup--kill-owned-buffer (frame)
  "Kill the private staging buffer belonging to FRAME."
  (let ((buffer (frame-parameter frame 'obp-desktop-popup-buffer)))
    (when (buffer-live-p buffer)
      (dolist (window (get-buffer-window-list buffer nil t))
        (set-window-buffer window (get-buffer-create "*scratch*")))
      (kill-buffer buffer))))

(defun obp/desktop-popup--delete-frame (frame)
  "Delete FRAME and its private staging buffer when they are live."
  (when (frame-live-p frame)
    (let ((buffer (frame-parameter frame 'obp-desktop-popup-buffer)))
      (delete-frame frame t)
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

(defun obp/desktop-popup--enforce-single-window ()
  "Keep dedicated desktop popup frames from exposing staging windows."
  (let ((frame (selected-frame)))
    (when (and (frame-parameter frame 'obp-desktop-popup-role)
               (> (length (window-list frame 'no-minibuf)) 1))
      (delete-other-windows (selected-window)))))

(add-hook 'window-configuration-change-hook
          #'obp/desktop-popup--enforce-single-window)

(defun obp/desktop-popup--abort-minibuffer-on-delete (frame)
  "Abort an active minibuffer owned by transient FRAME before deletion."
  (let ((minibuffer (active-minibuffer-window)))
    (when (and (frame-parameter frame 'obp-desktop-popup-role)
               (window-live-p minibuffer)
               (eq (window-frame minibuffer) frame))
      (abort-recursive-edit))))

(add-hook 'delete-frame-functions
          #'obp/desktop-popup--abort-minibuffer-on-delete)

;;;###autoload
(defun obp/desktop-universal-launcher ()
  "Open the universal launcher in a temporary minibuffer-only frame."
  (interactive)
  (require 'universal-launcher)
  (let* ((context (seq-find
         (lambda (frame)
                     (and (display-graphic-p frame)
                          (not (eq (frame-parameter frame 'minibuffer) 'only))))
                   (frame-list)))
         (frame (obp/desktop-popup--minibuffer-frame)))
    (unwind-protect
        (with-selected-frame frame
          (let ((minibuffer-follows-selected-frame t)
                (minibuffer-auto-raise t)
                ;; Keep this frame at the size requested above and by i3.
                ;; Auto-fitting starts it at one line and can leave its window
                ;; horizontally scrolled after Vertico grows the contents.
                (resize-mini-frames nil)
                (max-mini-window-height 15)
                (vertico-count 12)
                (universal-launcher-context-frame context))
            (minibuffer-with-setup-hook
                (lambda ()
                  (set-window-hscroll (selected-window) 0))
              (universal-launcher-popup context))))
      (obp/desktop-popup--delete-frame frame))))

(defun obp/desktop-popup--take-primary-selection ()
  "Return and clear the current X PRIMARY selection, when non-empty."
  (when-let ((selection
              (ignore-errors
                (gui-get-selection 'PRIMARY 'UTF8_STRING))))
    (unless (string-empty-p selection)
      ;; Match Emacs Everywhere: consuming the selection prevents an old X
      ;; selection from unexpectedly appearing in a later capture.
      (gui-backend-set-selection 'PRIMARY "")
      selection)))

(defun obp/desktop-popup--capture (role function &optional use-selection)
  "Run capture FUNCTION in a dedicated frame identified by ROLE.
When USE-SELECTION is non-nil, expose the X PRIMARY selection as `%i'."
  (let ((frame (obp/desktop-popup--ordinary-frame role)))
    (condition-case err
        (with-selected-frame frame
          ;; Org separately requests another window for its template selector
          ;; and its eventual capture buffer.  In this dedicated frame both
          ;; should replace the otherwise empty private staging buffer.
          (let ((display-buffer-overriding-action
                 '((display-buffer-same-window)))
                ;; `org-store-link-plist' is global and otherwise carries `%a'
                ;; from the previous capture into this unrelated desktop one.
                (org-store-link-plist nil)
                ;; A desktop capture has no meaningful Emacs source buffer.
                ;; Without this, Org may manufacture `%a' from whichever
                ;; buffer happened to be current before the popup was created.
                (org-capture-link-is-already-stored t)
                (org-capture-initial
                 (and use-selection
                      (obp/desktop-popup--take-primary-selection))))
            (funcall function)))
      ((error quit)
       (obp/desktop-popup--delete-frame frame)
       (signal (car err) (cdr err))))))

;;;###autoload
(defun obp/desktop-org-capture ()
  "Capture to Org with the X PRIMARY selection available as `%i'."
  (interactive)
  (obp/desktop-popup--capture 'capture #'org-capture t))

;;;###autoload
(defun obp/desktop-org-roam-capture ()
  "Capture to Org-roam with the X PRIMARY selection available as `%i'."
  (interactive)
  (require 'org-roam)
  (obp/desktop-popup--capture 'roam-capture #'org-roam-capture t))

;;;###autoload
(defun obp/desktop-org-roam-daily-capture ()
  "Capture into today's Org-roam daily in a dedicated floating frame."
  (interactive)
  (require 'org-roam-dailies)
  (obp/desktop-popup--capture
   'daily-capture #'org-roam-dailies-capture-today))

(defun obp/desktop-popup--finish-capture ()
  "Close the selected transient capture frame after finalization."
  (let ((frame (selected-frame)))
    (when (memq (frame-parameter frame 'obp-desktop-popup-role)
                obp/desktop-popup--capture-roles)
      (run-at-time 0 nil #'obp/desktop-popup--delete-frame frame))))

(with-eval-after-load 'org-capture
  (add-hook 'org-capture-after-finalize-hook
            #'obp/desktop-popup--finish-capture))

(provide 'desktop-emacs-popups)
;;; desktop-emacs-popups.el ends here

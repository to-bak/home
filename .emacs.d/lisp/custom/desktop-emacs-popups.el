;;; desktop-emacs-popups.el --- Dedicated desktop frames  -*- lexical-binding: t; -*-

;;; Commentary:
;; Open window-manager-triggered Emacs commands in purpose-built frames.  The
;; universal launcher uses a true minibuffer-only frame; capture commands use
;; ordinary frames whose lifetime follows the command they host.

;;; Code:

(require 'seq)

(defvar universal-launcher-context-frame)
(defvar vertico-count)
(defvar org-capture-initial)
(defvar org-capture-link-is-already-stored)
(defvar org-store-link-plist)
(defvar org-capture-current-plist)
(defvar org-capture-plist)
(defvar obp/desktop-popup--capture-frame nil
  "Frame owning the desktop capture currently being started.")

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

(defun obp/desktop-popup--delete-frame (frame)
  "Delete FRAME and its private staging buffer when they are live."
  (when (frame-live-p frame)
    (let ((buffer (frame-parameter frame 'obp-desktop-popup-buffer)))
      (delete-frame frame t)
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

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
  (let ((context (or (and (display-graphic-p)
                          (not (frame-parameter nil 'obp-desktop-popup-role))
                          (selected-frame))
                     (seq-find
                      (lambda (frame)
                        (and (display-graphic-p frame)
                             (not (frame-parameter frame 'obp-desktop-popup-role))
                             (not (eq (frame-parameter frame 'minibuffer) 'only))))
                      (frame-list))))
        (routing (default-toplevel-value 'minibuffer-follows-selected-frame))
        frame)
    (unwind-protect
        (progn
          ;; Emacs ignores dynamic bindings of this setting.  Keep the older
          ;; prompt in its own frame when opening and closing our nested one.
          (set-default-toplevel-value 'minibuffer-follows-selected-frame nil)
          (setq frame (obp/desktop-popup--minibuffer-frame))
          (with-selected-frame frame
            (let ((enable-recursive-minibuffers t)
                  (minibuffer-auto-raise t)
                  ;; Let i3 keep the frame at its requested size.
                  (resize-mini-frames nil)
                  (max-mini-window-height 15)
                  (vertico-count 12)
                  (universal-launcher-context-frame context))
              (minibuffer-with-setup-hook
                  (lambda () (set-window-hscroll (selected-window) 0))
                (universal-launcher-popup context)))))
      (unwind-protect
          (obp/desktop-popup--delete-frame frame)
        (set-default-toplevel-value 'minibuffer-follows-selected-frame routing)))))

(defun obp/desktop-popup--capture (role function)
  "Run capture FUNCTION in a dedicated frame identified by ROLE."
  (let ((frame (obp/desktop-popup--ordinary-frame role)))
    (condition-case err
        (with-selected-frame frame
          ;; Org separately requests another window for its template selector
          ;; and its eventual capture buffer.  In this dedicated frame both
          ;; should replace the otherwise empty private staging buffer.
          (let ((obp/desktop-popup--capture-frame frame)
                (display-buffer-overriding-action
                 '((display-buffer-same-window)))
                ;; `org-store-link-plist' is global and otherwise carries `%a'
                ;; from the previous capture into this unrelated desktop one.
                (org-store-link-plist nil)
                ;; A desktop capture has no meaningful Emacs source buffer.
                ;; Without this, Org may manufacture `%a' from whichever
                ;; buffer happened to be current before the popup was created.
                (org-capture-link-is-already-stored t)
                (org-capture-initial nil))
            (funcall function)))
      ((error quit)
       (obp/desktop-popup--delete-frame frame)
       (signal (car err) (cdr err))))))

;;;###autoload
(defun obp/desktop-org-capture ()
  "Open the Org capture template menu in a dedicated frame."
  (interactive)
  (obp/desktop-popup--capture 'capture #'org-capture))

;;;###autoload
(defun obp/desktop-org-roam-capture ()
  "Capture an Org-roam note in a dedicated frame."
  (interactive)
  (require 'org-roam)
  (obp/desktop-popup--capture 'roam-capture #'org-roam-capture))

;;;###autoload
(defun obp/desktop-org-roam-daily-capture ()
  "Capture into today's Org-roam daily in a dedicated floating frame."
  (interactive)
  (require 'org-roam-dailies)
  (obp/desktop-popup--capture
   'daily-capture #'org-roam-dailies-capture-today))

(defun obp/desktop-popup--remember-capture-frame ()
  "Record frame ownership for desktop and Org Protocol captures."
  (let ((frame (or obp/desktop-popup--capture-frame (selected-frame))))
    (when (and org-capture-mode
               (frame-live-p frame)
               (memq (frame-parameter frame 'obp-desktop-popup-role)
                     obp/desktop-popup--capture-roles))
      (setq org-capture-current-plist
            (plist-put org-capture-current-plist :obp-desktop-popup-frame frame))
      ;; Native Org Protocol capture may initially split its client frame.
      ;; Limit layout changes to initializing these dedicated capture frames.
      (delete-other-windows))))

(defun obp/desktop-popup--finish-capture ()
  "Close the frame belonging to the capture that just finished."
  (let ((frame (plist-get org-capture-plist :obp-desktop-popup-frame)))
    (when (and (frame-live-p frame)
               (memq (frame-parameter frame 'obp-desktop-popup-role)
                     obp/desktop-popup--capture-roles))
      (run-at-time 0 nil #'obp/desktop-popup--delete-frame frame))))

(with-eval-after-load 'org-capture
  (add-hook 'org-capture-mode-hook
            #'obp/desktop-popup--remember-capture-frame)
  (add-hook 'org-capture-after-finalize-hook
            #'obp/desktop-popup--finish-capture))

(provide 'desktop-emacs-popups)
;;; desktop-emacs-popups.el ends here

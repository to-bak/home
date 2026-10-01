;;; setup-windows.el --- Window placement and recovery -*- lexical-binding: t; -*-

(setq window-combination-resize t
      window-resize-pixelwise t)

;; Undo/redo window layouts with the built-in C-c left/right commands.
(winner-mode 1)

;; Repeat window movement with unmodified letters, then type normally to exit.
(require 'windmove)
(repeat-mode 1)
(setq windmove-wrap-around t)
(dolist (binding '(("h" . windmove-left) ("j" . windmove-down)
                   ("k" . windmove-up) ("l" . windmove-right)))
  (keymap-set other-window-repeat-map (car binding) (cdr binding))
  (put (cdr binding) 'repeat-map 'other-window-repeat-map))


;; Interactive window management, inspired by Karthink's wrappers.
(defun obp/split-window (side size)
  "Split toward SIDE, select the new window, and return it.
With a universal prefix SIZE, split the whole main editing area.
A numeric SIZE keeps the native line/column sizing behaviour."
  (select-window
   (split-window (if (consp size) (window-main-window) (selected-window))
                 (unless (consp size) size) side)))

(defun obp/split-window-below (&optional size)
  "Split below, select the new window, and choose a buffer."
  (interactive "P")
  (let ((window (obp/split-window 'below size)))
    (when (called-interactively-p 'any) (consult-buffer))
    window))

(defun obp/split-window-right (&optional size)
  "Split right, select the new window, and choose a buffer."
  (interactive "P")
  (let ((window (obp/split-window 'right size)))
    (when (called-interactively-p 'any) (consult-buffer))
    window))

(defun obp/delete-window-or-tab (&optional window)
  "Close WINDOW; close its tab or frame if it is the last editing window."
  (interactive)
  (let* ((window (or window (selected-window)))
         (frame (window-frame window)))
    (if (eq window (window-main-window frame))
        (with-selected-frame frame
          (if (and (bound-and-true-p tab-bar-mode)
                   (> (length (funcall tab-bar-tabs-function)) 1))
              (tab-bar-close-tab)
            (delete-frame frame)))
      (delete-window window))))

(defun obp/kill-buffer-and-window ()
  "Kill this buffer and close its window, tab, or frame.
If killing the buffer is cancelled, leave the layout intact."
  (interactive)
  (let ((window (selected-window)))
    (when (kill-buffer (current-buffer))
      (obp/delete-window-or-tab window))))

(defun obp/window-toggle-maximize ()
  "Maximize this window, or restore the layout saved on this frame."
  (interactive)
  (if (one-window-p t)
      (let ((saved (frame-parameter nil 'obp/window-configuration)))
        (if (window-configuration-p saved)
            (progn
              (set-window-configuration saved)
              (set-frame-parameter nil 'obp/window-configuration nil))
          (user-error "No maximized layout to restore")))
    (set-frame-parameter nil 'obp/window-configuration
                         (current-window-configuration))
    ;; Side windows cannot be maximized directly.  Show their buffer in a main
    ;; editing window first; the saved configuration retains the original layout.
    (when (window-parameter nil 'window-side)
      (let ((buffer (current-buffer)))
        (select-window
         (seq-find (lambda (window) (not (window-parameter window 'window-side)))
                   (window-list nil 'nomini)))
        (switch-to-buffer buffer)))
    (delete-other-windows)))

(keymap-global-set "<remap> <split-window-below>" #'obp/split-window-below)
(keymap-global-set "<remap> <split-window-right>" #'obp/split-window-right)
(keymap-global-set "<remap> <delete-window>" #'obp/delete-window-or-tab)
(keymap-global-set "<remap> <delete-other-windows>" #'obp/window-toggle-maximize)
(keymap-global-set "C-x q" #'obp/kill-buffer-and-window)
(keymap-global-set "C-x C-1" #'obp/window-toggle-maximize)

;; Reuse existing windows; otherwise keep documentation beside the editor and
;; build output below it.  Add rules without replacing other packages' rules.
(dolist (rule
         '(((derived-mode . help-mode)
            (display-buffer-reuse-window display-buffer-in-side-window)
            (side . right)
            (slot . 0)
            (window-width . 0.4))
           ((derived-mode . compilation-mode)
            (display-buffer-reuse-window display-buffer-in-side-window)
            (side . bottom)
            (slot . 0)
            (window-height . 0.3))
           ("\\`\\*\\(?:Messages\\|Warnings\\|Compile-Log\\|Backtrace\\|Async Shell Command\\)\\*\\'\\|Output\\*\\'"
            (display-buffer-reuse-window display-buffer-in-side-window)
            (side . bottom)
            (slot . 1)
            (window-height . 0.25))))
  (add-to-list 'display-buffer-alist rule t))

;;; setup-windows.el ends here

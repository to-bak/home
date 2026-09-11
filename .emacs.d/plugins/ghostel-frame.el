;;; ghostel-frame.el --- Open Ghostel in a dedicated frame  -*- lexical-binding: t; -*-

;;; Code:

;;;###autoload
(defun my/new-frame-with-ghostel ()
  "Create a new Emacs frame containing a fresh Ghostel terminal."
  (interactive)
  (require 'ghostel)
  (let ((frame (make-frame '((explicit-ghostel . t)
                             (minibuffer . t)))))
    (select-frame-set-input-focus frame)
    (delete-other-windows)
    (switch-to-buffer
     (ghostel (format "*ghostel-%s*" (frame-parameter frame 'name))))
    (delete-other-windows)))

(provide 'ghostel-frame)
;;; ghostel-frame.el ends here

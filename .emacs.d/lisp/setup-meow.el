;;; setup-meow.el --- Modal editing with familiar Vim keys -*- lexical-binding: t; -*-

;; Starting states: add major modes here; derived modes inherit their rule.
;; Capture and Emacs Everywhere are minor modes, handled by hooks below.
(defconst obp/meow-initial-modes
  '((insert
     comint-mode
     eshell-mode
     term-mode
     vterm-mode
     eat-mode
     ghostel-mode
     agent-shell-mode)
    (motion
     help-mode)
    (normal
     fundamental-mode
     conf-mode
     text-mode
     prog-mode
     special-mode
     org-agenda-mode
     dired-mode
     magit-mode))
  "Major modes grouped by their initial Meow state.")

(defun obp/meow-insert-at-indentation ()
  "Enter Insert at the first nonblank character of the current line."
  (interactive)
  (deactivate-mark)
  (back-to-indentation)
  (meow-insert))

(defun obp/meow-append-at-line-end ()
  "Enter Insert at the end of the current line."
  (interactive)
  (deactivate-mark)
  (end-of-line)
  (meow-append))

(defun obp/meow-join-next-line ()
  "Join the next line to this one, removing indentation."
  (interactive)
  (deactivate-mark)
  (delete-indentation 1))

(defvar obp/meow-avy-expanding nil
  "Non-nil while choosing or expanding a Meow selection with Avy.")

(defun obp/meow-avy-hints (num)
  "Choose among NUM Meow expansion endpoints using Avy letters.
Keep Meow's selection anchor, direction, type and history.  The current
endpoint is also a candidate, allowing the initial selection to be accepted."
  (unless (or obp/meow-avy-expanding (zerop num))
    (require 'avy)
    (meow--remove-expand-highlights)
    (meow--remove-match-highlights)
    (meow--remove-search-indicator)
    (let* ((obp/meow-avy-expanding t)
           (nav (if (meow--direction-backward-p)
                    (car meow--expand-nav-function)
                  (cdr meow--expand-nav-function)))
           (start (window-start))
           (end (window-end nil t))
           (targets (list (cons (point) 0)))
           chosen)
      (save-mark-and-excursion
        (let ((previous (point)))
          (catch 'finished
            (dotimes (index num)
              (let ((next (funcall nav)))
                (unless (and next (> next 0) (/= next previous)
                             (<= start next end))
                  (throw 'finished nil))
                (goto-char next)
                (setq previous next)
                (push (cons next (1+ index)) targets))))))
      (setq targets (nreverse targets))
      (let ((avy-all-windows nil)
            (avy-dispatch-alist nil)
            (avy-action-oneshot nil)
            (avy-pre-action #'ignore)
            (avy-action (lambda (position)
                          (setq chosen (cdr (assq position targets))))))
        (avy-process (mapcar #'car targets)))
      ;; Expanding regenerates hints; the guard prevents another Avy prompt.
      (when (and chosen (> chosen 0))
        (meow-expand chosen)))))

(use-package meow
  :straight (:type git :host github :repo "meow-edit/meow")
  :demand t
  :hook ((org-capture-mode . meow-insert-mode)
         (emacs-everywhere-mode . meow-insert-mode))
  :config
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty
        ;; Space accesses underlying keys without sharing C-c or C-x prefixes.
        meow-keypad-leader-transparent t
        meow-keypad-start-keys nil
        meow-keypad-leader-dispatch (make-sparse-keymap))

  (setq meow-mode-state-list
        (cl-loop for (state . modes) in obp/meow-initial-modes
                 append (cl-loop for mode in modes
                                 collect (cons mode state))))

  (keymap-set meow-insert-state-keymap "C-g" #'meow-insert-exit)

  ;; Motion buffers keep their native Space; Normal uses transparent Space.
  (meow-motion-define-key '("SPC" . nil) '("<escape>" . keyboard-quit))
  ;; z was selection history; reserve it for Vim-style window commands.
  (keymap-set meow-normal-state-keymap "z" (make-sparse-keymap))
  (meow-normal-define-key
   '("h" . meow-left)
   '("j" . meow-next)
   '("k" . meow-prev)
   '("l" . meow-right)
   '("H" . meow-left-expand)
   '("J" . obp/meow-join-next-line)
   '("K" . meow-prev-expand)
   '("L" . meow-right-expand)
   '("w" . meow-next-word)
   '("b" . meow-back-word)
   '("e" . meow-mark-word)
   '("W" . meow-next-symbol)
   '("B" . meow-back-symbol)
   '("E" . meow-mark-symbol)
   '("v" . meow-mark-word)
   '("V" . meow-line)
   '("I" . obp/meow-insert-at-indentation)
   '("A" . obp/meow-append-at-line-end)
   '("i" . meow-insert)
   '("a" . meow-append)
   '("o" . meow-open-below)
   '("O" . meow-open-above)
   '("d" . meow-kill)
   '("D" . kill-line)
   '("c" . meow-change)
   '("x" . meow-delete)
   '("y" . meow-save)
   '("p" . meow-yank)
   '("u" . meow-undo)
   '("U" . undo-redo)
   '("/" . meow-visit)
   '("n" . meow-search)
   '(":" . execute-extended-command)
   '("g g" . beginning-of-buffer)
   '("G" . end-of-buffer)
   '("^" . back-to-indentation)
   '("$" . end-of-line)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("Z" . meow-pop-selection)
   '("z z" . recenter)
   '("<escape>" . meow-cancel-selection))
  ;; Keep native numeric expansion and explicit prefix arguments available.
  ;; 0 expands to target 10; explicit counts still work with C-u or M-digits.
  (dotimes (digit 10)
    (meow-normal-define-key
     (cons (number-to-string digit)
           (intern (format "meow-expand-%d" digit)))))

  ;; One adapter covers all native numbered word/symbol/line/block/find hints.
  (advice-add 'meow--highlight-num-positions :override #'obp/meow-avy-hints)

  (meow-global-mode 1))

;;; setup-meow.el ends here

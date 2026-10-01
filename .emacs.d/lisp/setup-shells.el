;;; setup-shells.el --- Project terminals and Eshell -*- lexical-binding: t; -*-

(defvar-local obp/ghostel-popup-p nil
  "Non-nil for a project terminal opened as a popup.")

(defun obp/ghostel-project-toggle ()
  "Show or hide the current project's Ghostel popup without killing its shell."
  (interactive)
  (require 'ghostel)
  ;; Match the terminal's original project even after running cd in the shell.
  (let* ((ghostel-project-buffer-scope 'identity)
         (window (seq-some
                  (lambda (buffer)
                    (and (buffer-local-value 'obp/ghostel-popup-p buffer)
                         (get-buffer-window buffer)))
                  (ghostel-project-buffer-list))))
    (if window
        (quit-window nil window)
      ;; Override Ghostel's usual same-window display, including on creation.
      (let* ((display-buffer-overriding-action
              '((display-buffer-reuse-window display-buffer-at-bottom)
                (window-height . 0.5)))
             (buffer (ghostel-project)))
        (with-current-buffer buffer
          (setq-local obp/ghostel-popup-p t
                      popper-popup-status 'popup))))))

(use-package ghostel
  :commands (ghostel ghostel-project)
  :bind (("C-c v" . obp/ghostel-project-toggle)
         ("C-c V" . ghostel)
         :map project-prefix-map ("t" . obp/ghostel-project-toggle))
  :init
  ;; Keep the popup placement when Popper reopens this terminal, too.
  (add-to-list 'display-buffer-alist
               '((lambda (buffer _action)
                   (buffer-local-value 'obp/ghostel-popup-p (get-buffer buffer)))
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (window-height . 0.5)))
  ;; Preserve the original Fish shell when it is installed.
  (when-let* ((fish (executable-find "fish")))
    (setq ghostel-shell fish)))

(defvar obp/eshell-buffer nil
  "Most recently used Eshell buffer for toggling.")

(defun obp/eshell-toggle (&optional arg)
  "Show or hide the last Eshell buffer.
With prefix ARG, pass it to `eshell' to create or select another session."
  (interactive "P")
  (cond
   (arg (setq obp/eshell-buffer (eshell arg)))
   ((derived-mode-p 'eshell-mode)
    (setq obp/eshell-buffer (current-buffer))
    (quit-window))
   ((buffer-live-p obp/eshell-buffer)
    (pop-to-buffer obp/eshell-buffer))
   (t (setq obp/eshell-buffer (eshell)))))

(defun obp/eshell-prompt ()
  "Show the working directory, Git branch, and last command's status."
  (let ((branch (and (not (file-remote-p default-directory))
                     (vc-git-root default-directory)
                     (vc-git--symbolic-ref default-directory))))
    (concat (propertize (abbreviate-file-name (eshell/pwd))
                        'face 'font-lock-keyword-face)
            (when branch
              (propertize (format " [%s]" branch) 'face 'font-lock-builtin-face))
            (propertize " λ " 'face (if (zerop eshell-last-command-status)
                                        'success 'error)))))

(defun obp/eshell-output-region (&optional include-input)
  "Return the last output's bounds, including input if INCLUDE-INPUT is non-nil."
  (cons (if include-input (eshell-beginning-of-input) (eshell-beginning-of-output))
        (eshell-end-of-output)))

(defun obp/eshell-copy-output (&optional include-input)
  "Copy the last output; with a prefix, include its command."
  (interactive "P")
  (let ((bounds (obp/eshell-output-region include-input)))
    (copy-region-as-kill (car bounds) (cdr bounds))))

(defun obp/eshell-export-output (&optional include-input)
  "Show the last output in a read-only buffer; with a prefix, include its command."
  (interactive "P")
  (let* ((bounds (obp/eshell-output-region include-input))
         (text (buffer-substring-no-properties (car bounds) (cdr bounds)))
         (buffer (get-buffer-create "*Eshell output*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert text)
        (goto-char (point-min))
        (special-mode)))
    (pop-to-buffer buffer)))

(defun obp/eshell-run-in-compilation ()
  "Run the current input with the system shell in a compilation buffer."
  (interactive)
  (let ((command (buffer-substring-no-properties eshell-last-output-end (point-max))))
    (when (string-empty-p (string-trim command))
      (user-error "Enter a command first"))
    (eshell-add-input-to-history command)
    (eshell-reset)
    (compile command)))

(use-package eshell
  :straight nil
  :commands eshell
  :bind (("C-S-e" . obp/eshell-toggle)
         ("C-$" . obp/eshell-toggle)
         :map eshell-mode-map
         ("C-c C-SPC" . eshell-mark-output)
         ("C-c M-w" . obp/eshell-copy-output)
         ("C-c C-l" . obp/eshell-export-output)
         ("C-<return>" . obp/eshell-run-in-compilation))
  :init
  (setq eshell-hist-ignoredups t
        eshell-history-size 4096
        eshell-destroy-buffer-when-process-dies t
        eshell-prompt-regexp "^.* λ "
        eshell-prompt-function #'obp/eshell-prompt)
  :config
  (require 'vc-git)
  ;; Let global Consult search bindings work at the prompt.
  (with-eval-after-load 'em-hist
    (keymap-unset eshell-hist-mode-map "M-s")
    (keymap-set eshell-hist-mode-map "M-r" #'consult-history))
  (add-hook 'eshell-pre-command-hook #'eshell-save-some-history)

  (defun eshell/z (&optional regexp)
    "Change to a previously visited directory, choosing with completion."
    (eshell/cd
     (if regexp (eshell-find-previous-directory regexp)
       (completing-read "Directory: "
                        (delete-dups (ring-elements eshell-last-dir-ring)) nil t)))))

(use-package eat
  ;; Include assets that Straight's default file selection would omit.
  :straight (:type git :repo "https://codeberg.org/akib/emacs-eat"
             :files (:defaults "term" "terminfo" "integration"))
  :commands eat
  ;; These are global modes: enable once, before the first Eshell starts.
  :hook ((eshell-load . eat-eshell-mode)
         (eshell-load . eat-eshell-visual-command-mode))
  :bind (:map eat-semi-char-mode-map ("M-v" . eat-emacs-mode)
         :map eat-mode-map ("RET" . eat-semi-char-mode))
  :init
  (setq eat-kill-buffer-on-exit t))

;;; setup-shells.el ends here

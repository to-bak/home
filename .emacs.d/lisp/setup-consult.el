;;; setup-consult.el --- Search and navigation -*- lexical-binding: t; -*-

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("M-s l" . consult-line)
         ("M-s g" . consult-ripgrep)
         ("M-g i" . consult-imenu)
         ("C-x r b" . consult-bookmark)
         ("C-c r" . consult-recent-file))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (setq consult-narrow-key "<")

  ;; Extend upstream arguments, preserving future defaults and avoiding duplicates.
  (when (stringp consult-ripgrep-args)
    (setq consult-ripgrep-args (split-string-and-unquote consult-ripgrep-args)))
  (dolist (argument '("--hidden" "--glob=!.git/"))
    (add-to-list 'consult-ripgrep-args argument t))

  ;; Preview files deliberately, avoiding automatic image/file opening.
  (consult-customize
   consult-recent-file consult-bookmark
   consult-source-file-register consult-source-bookmark
   consult-source-recent-file consult-source-project-recent-file
   consult-source-project-recent-file-hidden
   :preview-key "M-."
   consult-line consult-ripgrep
   :preview-key '(:debounce 0.2 any)))

;;; setup-consult.el ends here

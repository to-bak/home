;;; setup-project.el --- Project navigation -*- lexical-binding: t; -*-

;; Register the built-in recipe so package dependencies use native project.el too.
(use-package project
  :straight (:type built-in)
  :demand t
  :init
  (keymap-global-set "C-c p" project-prefix-map)
  :bind (:map project-prefix-map
              ("b" . consult-project-buffer)
              ("r" . consult-ripgrep)))

;; One picker for open buffers and every project file, including unopened files.
(use-package consult-project-extra
  :bind (:map project-prefix-map ("f" . consult-project-extra-find))
  :config
  (setq consult-project-extra-sources
        '(consult-project-extra--source-buffer
          consult-project-extra--source-file))
  ;; Preserve the file-opening action and preview only on request.
  (consult-customize consult-project-extra--source-file
    :state #'consult--file-preview
    :preview-key "M-."))

;;; setup-project.el ends here

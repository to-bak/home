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
(use-package consult-project-pickers
  :straight nil
  :load-path "lisp/custom"
  :bind (:map project-prefix-map ("f" . consult-project-pickers-find)))

;;; setup-project.el ends here

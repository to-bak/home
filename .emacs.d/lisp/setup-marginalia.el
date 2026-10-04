;;; setup-marginalia.el --- Completion annotations -*- lexical-binding: t; -*-

(use-package marginalia
  :demand t
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :config
  (marginalia-mode 1))

;;; setup-marginalia.el ends here

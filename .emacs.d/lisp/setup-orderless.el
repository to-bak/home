;;; setup-orderless.el --- Completion matching -*- lexical-binding: t; -*-

(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        ;; Basic handles TRAMP hostnames; partial-completion handles paths.
        completion-category-overrides '((file (styles basic partial-completion)))
        completion-pcm-leading-wildcard t))

;;; setup-orderless.el ends here

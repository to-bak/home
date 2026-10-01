;;; setup-completion-preview.el --- Personal completion-preview setup -*- lexical-binding: t; -*-

(use-package completion-preview
  :straight nil
  :demand t
  :bind (:map completion-preview-active-mode-map
              ("M-n" . completion-preview-next-candidate)
              ("M-p" . completion-preview-prev-candidate))
  ;; TAB accepts the inline suggestion; M-TAB opens normal completion.
  :hook ((prog-mode text-mode ielm-mode shell-mode eshell-mode)
         . completion-preview-mode))

;;; setup-completion-preview.el ends here

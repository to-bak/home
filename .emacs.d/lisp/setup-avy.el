;;; setup-avy.el --- Jump to visible text -*- lexical-binding: t; -*-

(use-package avy
  :bind (("C-s" . avy-goto-word-0)
         ("M-j" . avy-goto-char-timer)
         ("C-'" . avy-goto-word-0)
         ("C-M-'" . avy-resume)
         ("M-s j" . avy-goto-char-2)
         ("M-s M-p" . avy-goto-line-above)
         ("M-s M-n" . avy-goto-line-below)
         ("M-s M-l" . avy-goto-end-of-line)
         :map isearch-mode-map
         ("M-j" . avy-isearch)
         ("C-'" . avy-isearch))
  :init
  (setq avy-timeout-seconds 0.3))

;;; setup-avy.el ends here

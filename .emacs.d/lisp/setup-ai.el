;;; setup-ai.el --- Chat and agent workflows -*- lexical-binding: t; -*-

(use-package gptel
  :commands (gptel gptel-send gptel-menu)
  :bind (("C-c j" . gptel-menu)
         ("C-c M-j" . gptel))
  :config
  (when host/gptel-config
    (funcall host/gptel-config)))

;;; setup-ai.el ends here

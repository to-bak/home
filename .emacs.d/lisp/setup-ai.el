;;; setup-ai.el --- Chat and agent workflows -*- lexical-binding: t; -*-

(use-package gptel
  :commands (gptel gptel-send gptel-menu)
  :bind (("C-c j" . gptel-menu)
         ("C-c M-j" . gptel))
  :config
  (setq gptel-expert-commands t)

  ;; Select with @ in `gptel-menu', or include @explain in a prompt.
  (gptel-make-preset 'explain
    :description "Explain code step by step"
    :system "You are a patient programming tutor. Explain the supplied code step by step, including the reasoning behind it. Use small examples when helpful.")

  (when host/gptel-config
    (funcall host/gptel-config)))

;;; setup-ai.el ends here

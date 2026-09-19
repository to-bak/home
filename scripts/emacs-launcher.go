package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

const pluginDir = "@pluginDir@"

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: emacs-launcher <elisp-command>")
		fmt.Fprintln(os.Stderr, "example: emacs-launcher '(obp/desktop-universal-launcher)'")
		os.Exit(1)
	}

	// Return the server request before starting an interactive command.  A
	// completing-read inside server-eval would otherwise block later requests.
	elisp := fmt.Sprintf(
		"(progn (add-to-list 'load-path %q) (require 'desktop-emacs-popups) (run-at-time 0 nil (lambda () %s)))",
		pluginDir,
		strings.Join(os.Args[1:], " "),
	)

	if err := exec.Command("emacsclient", "-n", "-e", elisp).Run(); err != nil {
		fmt.Fprintf(os.Stderr, "emacsclient: %v\n", err)
		os.Exit(1)
	}
}

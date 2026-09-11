// ~/.config/sway/scripts/emacs-launcher.go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: emacs-launcher <elisp-command>")
		fmt.Fprintln(os.Stderr, "example: emacs-launcher '(universal-launcher-popup)'")
		os.Exit(1)
	}
	// Return the server request before starting an interactive command.  A
	// completing-read inside server-eval would otherwise block every later
	// emacsclient request until its minibuffer exits.
	elisp := fmt.Sprintf("(run-at-time 0 nil (lambda () %s))", strings.Join(os.Args[1:], " "))

	if err := exec.Command("emacsclient", "-n", "-e", elisp).Run(); err != nil {
		fmt.Fprintf(os.Stderr, "emacsclient: %v\n", err)
		os.Exit(1)
	}
}

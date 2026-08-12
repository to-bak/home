EMACS ?= emacs

PROJECT_TABSPACES_LOAD_PATH = \
	-L straight/repos/project \
	-L straight/repos/consult \
	-L straight/repos/compat \
	-L straight/repos/tabspaces \
	-L plugins \
	-L test

.PHONY: test test-project-tabspaces

test: test-project-tabspaces

test-project-tabspaces:
	$(EMACS) -Q --batch $(PROJECT_TABSPACES_LOAD_PATH) \
		-l project-tabspaces-test \
		-f ert-run-tests-batch-and-exit

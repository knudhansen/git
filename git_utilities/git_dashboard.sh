#!/bin/bash

# this script periodically shows the git status, a list of the stashes and a git log.

watch -n 10 --color "printf '\nGIT STATUS\n\n' && git -c color.ui=always status && printf '\nGIT STASHES\n\n' && git stash list && printf '\nGIT LOG\n\n' && git -c color.ui=always log --oneline --decorate --graph --all"



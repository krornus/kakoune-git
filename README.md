# kakoune-git

This plugin provides extra git integration for kakoune

# Install

Place in autoload/ or use [plug.kak](https://github.com/andreyorst/plug.kak).

# Usage

Usage is inspired by the builtin grep.kak. Currently, only two commands are provided:

`git-list-branch-files [branch]`: Create scratch buffer which lists files for the given branch (default: master)
`git-show-branch-file [file] [branch]`: Open the file <file> on branch <branch> in a scratch buffer. (file default: current buffer, branch default: master)


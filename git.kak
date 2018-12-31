declare-option -docstring "current branch being listed" str gitbranch
declare-option -docstring "face for the active line" str git_list_active_face "rgb:FF805C+b"
declare-option -docstring "face for inactive file names" str git_list_file_face "rgb:78C29E"
declare-option -docstring "face for inactive path preceding file name" str git_list_path_face "rgb:547980"

declare-option -hidden int git_current_line 0

hook -group grep-highlight global WinSetOption filetype=git-tree %{
    add-highlighter window/git-tree group

    add-highlighter window/git-tree/inactive regex '(?S)^(.+/)?([^/]+)$' \
        %sh{echo "1:${kak_opt_git_list_path_face}"} %sh{echo "2:${kak_opt_git_list_file_face}"}

    add-highlighter window/git-tree/active line %{%opt{git_current_line}} \
        %sh{echo "$kak_opt_git_list_active_face"}
}

hook global WinSetOption filetype=git-tree %{
    hook buffer -group git-hooks NormalKey <ret> git-list-jump
}


define-command git-show-branch-file -params 0..2 -docstring %{
git-show-branch-file [file=<current buffer>] [branch=master]
    open a scratch buffer for file on branch
    if only one argument is given, it is assumed
    to be on branch master
} %{
    evaluate-commands %sh{
        tmp=${TMPDIR:-/tmp}
        file=${1:-${kak_bufname}}
        branch=${2:-master}
        fifo=$(mktemp -d "${tmp}/$(echo ${file}.${branch} | tr / _).XXXXXXXX")/fifo
        mkfifo ${fifo}
        (git show ${branch}:${file} > ${fifo} 2>&1) > /dev/null 2>&1 < /dev/null &
        printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
               edit! -fifo ${fifo} ${branch}:${file}
               hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${fifo}) } }
        }"
    }
}

define-command git-list-branch-files -params 0..1 -docstring %{
git-list-branch-files [branch=master]
    open a scratch buffer which lists all files in a branch
} %{
    evaluate-commands %sh{
        tmp=${TMPDIR:-/tmp}
        fifo=$(mktemp -d "${tmp}/lstree.$(echo ${1:-master} | tr / _).XXXXXXXX")/fifo
        mkfifo ${fifo}
        (git ls-tree -r --name-only ${1:-master} > ${fifo} 2>&1) > /dev/null 2>&1 < /dev/null &
        printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
               edit! -fifo ${fifo} *${1:-master}*
               set-option buffer filetype git-tree
               set-option buffer git_current_line 0
               hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${fifo}) } }
        }"
    }
}

define-command -hidden git-list-jump %{
    evaluate-commands %{
        try %{
            execute-keys "<a-x>H"
            set-option buffer git_current_line %val{cursor_line}
            evaluate-commands -try-client %opt{toolsclient} %sh{
                branch=$(echo $kak_bufname | tr -d "*")
                echo "git-show-branch-file $kak_reg_dot $branch"
            }
        }
    }
}

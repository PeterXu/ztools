#!/usr/bin/env bash
#


### gitx options

_git_opts_="" 
_git_opts_="$_git_opts_ add branch checkout cherry-pick clean clone commit"
_git_opts_="$_git_opts_ diff fetch format-patch gc grep init log"
_git_opts_="$_git_opts_ merge mv pull push rebase reset restore revert rm"
_git_opts_="$_git_opts_ show stash status submodule switch tag"
_git_opts_="$_git_opts_ config reflog remote"
_git_opts_="$_git_opts_ fsck help"
_git_opts_="$_git_opts_ apply"
_git_opts_="$_git_opts_ "


### gitx complete

_gitx_go() {
    local ret=0
    case "$1" in
        gitx) _gitx_all_commands;;
        *)
            echo "$_git_opts_" | grep " $1 " >/dev/null
            ret="$?"
            [ $ret -eq 0 ] && _gitx_$1;;
    esac
    return $ret
}

_gitx() {
    local pos=${COMP_CWORD}
    local cur=$(echo ${COMP_WORDS[pos]})
    if [ $pos -ge 2 ]; then
        cur=$(echo ${COMP_WORDS[1]})
    fi
    _gitx_go "$cur"
    if [ $? -eq 1 ]; then
        _gitx_go "${COMP_WORDS[pos-1]}"
    fi
}


### init git shell
__init_git() {
    _completex _gitx gitx
    alias gitx="git"
}



### =============
### gitx commands

_gitx_all_commands() {
    local opts="$_git_opts_"
    _tablist2 "" "$opts"
}

_gitx_all_branches() {
    local opts="FETCH_HEAD HEAD ORIG_HEAD"
    local opts1=$(git branch | awk '{p=$1;if(p == "*") p=$2;print p}')
    local opts2=$(git branch -r | awk '{p=$1; if(p == "*") p=$2;print p}')
    _tablist2 "" "$opts $opts1 $opts2"
}


## gitx
_gitx_add() {
    local opts=$(git status -s | awk '{print $2}')
    _tablist2 "" "$opts"
}
_gitx_branch() {
    _gitx_all_branches
}
_gitx_checkout() {
    _gitx_all_branches
}
_gitx_cherry_pick() {
    _gitx_all_branches
}
_gitx_clean() {
    local opts=$(git status -s | awk '{print $2}')
    _tablist2 "" "$opts"
}
_gitx_clone() {
    local opts
}
_gitx_commit() {
    local opts
}


## gitx
_gitx_diff() {
    _gitx_all_branches
}
_gitx_fetch() {
    local opts0=$(git remote)
    local opts1="HEAD:HEAD"
}
_gitx_format_patch() {
    _gitx_all_branches
}
_gitx_gc() {
    local opts
}
_gitx_grep() {
    local opts
}
_gitx_init() {
    local opts
}
_gitx_log() {
    _gitx_all_branches
}


## gitx
_gitx_merge() {
    _gitx_all_branches
}
_gitx_mv() {
    local opts
}
_gitx_pull() {
    local opts
}
_gitx_push() {
    local opts
}
_gitx_rebase() {
    _gitx_all_branches
}
_gitx_reset() {
    _gitx_all_branches
}
_gitx_restore() {
    local opts
}
_gitx_revert() {
    local opts
}
_gitx_rm() {
    local opts
}

## gitx
_gitx_show() {
    _gitx_all_branches
}
_gitx_stash() {
    local opts
}
_gitx_status() {
    local opts
}
_gitx_submodule() {
    local opts
}
_gitx_switch() {
    _gitx_all_branches
}
_gitx_tag() {
    local opts
}

## gitx
_gitx_config() {
    local opts="add branch checkout commit core diff difftool format gc log"
    _tablist2 "" "$opts"
}
_gitx_reflog() {
    local opts="show expire delete exists"
    _tablist2 "" "$opts"
}
_gitx_remote() {
    local opts="add rename remove set-head set-branches get-url set-url show prune update"
    _tablist2 "" "$opts"
}

_gitx_fsck() {
    local opts
}
_gitx_help() {
    local opts="$_git_opts_"
    _tablist2 "" "$opts"
}

_gitx_apply() {
    local opts
}


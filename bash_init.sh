#!/usr/bin/env bash
# bash init script

# order of operations:
# for interactive login shells:
#   /etc/profile
#     /etc/bash.bashrc (does basically nothing lol)
#     /etc/profile.d/*
#       ...
#   ~/.bash_profile (or ~/.bash_login or ~/.profile; symlink to this file)
#
# interactive non-login shells:
#   /etc/bash.bashrc (does basically nothing lol)
#   ~/.bashrc (symlink to this file)
# non-interactive shells:
#   $BASH_ENV

function _bash_init {
    shopt -s checkhash
    shopt -s cdspell
    shopt -s dirspell
    shopt -s no_empty_cmd_completion

    # shopt -s extdebug

    # set -eu -o functrace errtrace
    # _BASHLIB_LOGLEVEL=debug
    # _BASHLIB_FLAGS=:replace_exec:stacktrace:

    if [[ ! ${_BASH_INIT_ROOT-} ]]; then
        _BASH_INIT_ROOT=$(dirname "$(realpath "$BASH_SOURCE")")
        export _BASH_INIT_ROOT
    fi

    local item
    for item in "${_BASH_INIT_ROOT-}"/bash_init/*; do
        if [[ $item == *.@(sh|bash) ]]; then
            source "$item"
        else
            echo >&2 "[!] $FUNCNAME: Will not source file: $item"
        fi
    done
}

if [[ ! ${_BASH_INIT_SKIP-} ]]; then
    _bash_init
fi

# ignore any crap installer scripts try to append to this file
return 0

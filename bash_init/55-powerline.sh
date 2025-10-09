# setup powerline
# shellcheck disable=2034

function find-powerline-root {
    if [[ -d ${POWERLINE_ROOT-} && $POWERLINE_ROOT == */powerline ]]; then
        _if_verbose _warn "POWERLINE_ROOT already set"
        return 0
    fi

    unset POWERLINE_ROOT || true

    local powerline_path
    powerline_path=$(realpath "$(type -P powerline)") || {
        _if_verbose _warn "Powerline executable not found"
        return 1
    }

    if [[ $powerline_path == */.pyenv/* ]] && type -P pyenv > /dev/null; then
        powerline_path=$(realpath "$(pyenv which powerline)") || {
            throw "Pyenv Powerline installation appears broken"
        }
    fi

    local first_match
    for first_match in "${powerline_path%/*/*}"/lib/python*/site-packages/powerline; do
        export POWERLINE_ROOT=$first_match
        return 0
    done

    _if_verbose _warn "Powerline root not found"
    return 1
}

if [[ ! -d ${POWERLINE_ROOT-} ]]; then
    find-powerline-root
fi

[[ ${_SHELL_INTERACTIVE-} ]] || return 0

if [[ -d ${POWERLINE_ROOT-} ]]; then
    # if `ss` is unavailable, or no matching powerline daemon socket exists
    if ! havebin ss || [[ -z $(ss -Hax src @powerline-ipc-$UID) ]]; then
        # start powerline daemon
        powerline-daemon -q || true
    fi

    export POWERLINE_BASH_CONTINUATION=1
    export POWERLINE_BASH_SELECT=1

    # gross hack to skip slow, redundant checks
    POWERLINE_COMMAND=powerline
    POWERLINE_CONFIG_COMMAND=powerline-config
    # shellcheck disable=SC2329
    function powerline-config {
        # shellcheck disable=SC2317
        return 0
    }

    # withflags +veux . "${POWERLINE_ROOT:?}/bindings/bash/powerline.sh"
    withflags +eu -- source "${POWERLINE_ROOT:?}/bindings/bash/powerline.sh"
    unset -f powerline-config

    # 1. I want to have `$SHLVL` in my prompt
    # 2. as of (5.2.26.1), bash seems to have a bug such that when the last
    #    command in a subshell is an external process, the SHLVL passed to it
    #    is too small by one
    # 3. powerline executes its process by itself in a subshell
    # 4. so i'm patching the function wrapping it to add a final `return`

    declare -a func_lines
    # if we succeed in reading the lines of the function `_powerline_prompt` ...
    if get_array func_lines declare -f _powerline_prompt 2> /dev/null; then
        # and the last statement does not match `/ *return( .*)?$/` ...
        if [[ ! ${func_lines[-2]} =~ ^\ *return( .*)?$ ]]; then
            # remove the final closing brace
            unset 'func_lines[-1]'
            # add a `return` statement
            func_lines=("${func_lines[@]}" "return" "}")
            # and re-evaluate the reconstructed function
            eval "$(each "${func_lines[@]}")"
        fi
    fi
    unset func_lines
fi

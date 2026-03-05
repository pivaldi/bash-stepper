#!/bin/bash

BOLD=
OFFBOLD=
RESET_COLOR=
RED=
GREEN=
YELLOW=
BLUE=
BLUE_CYAN=
GRAY_LIGHT=

if [ -t 1 ]; then
    BOLD=$(tput bold)
    OFFBOLD=$(tput sgr0)
    RESET_COLOR="$(tput sgr0)"
    RED="$(
        tput bold
        tput setaf 1
    )"
    GREEN="$(
        tput bold
        tput setaf 2
    )"
    YELLOW="$(
        tput bold
        tput setaf 3
    )"
    BLUE="$(
        tput bold
        tput setaf 4
    )"
    BLUE_CYAN="$(
        tput bold
        tput setaf 6
    )"
    GRAY_LIGHT="$(tput setaf 250)"
fi

DOING_MSG=

ST_H1=
ST_H2=
ST_H3=
ST_DOING=
ST_DONE=
ST_SUCCESS=
ST_NOTHING=
ST_SKIPPED=
ST_WARN=
ST_FAIL=
ST_ABORT=
ST_DO=

[ -z "${ST_QUIET:-}" ] && {
    ST_H1='st.h1> '
    ST_H2='st.h2> '
    ST_H3='st.h3> '
    ST_DOING='st.doing> '
    ST_DONE='st.done> '
    ST_SUCCESS='st.success> '
    ST_NOTHING='st.nothingtd> '
    ST_SKIPPED='st.skipped> '
    ST_WARN='st.warn> '
    ST_FAIL='st.fail '
    ST_ABORT='st.abort> '
    ST_DO='st.do> '
}

function st.cmd.exists() {
    command -v "$1" >/dev/null 2>&1
}

## Usage: st.var.exists A_VAR && echo PASS
function st.var.exists() {
    [ -n "${!1:-}" ]
}

function st.h1() {
    echo -e "${ST_H1}${BOLD}$1${OFFBOLD}"
}

function st.h2() {
    echo -e "${ST_H2}${BOLD}$1${OFFBOLD}"
}

function st.h3() {
    echo -e "${ST_H3}${BOLD}$1${OFFBOLD}"
}

function st.doing() {
    DOING_MSG=$1

    echo "${ST_DOING}${BLUE}${DOING_MSG:-…}$RESET_COLOR"
}

function st.done() {
    local DONE="${1:-[DONE]}"

    echo "${ST_DONE}${DOING_MSG:-} : ${GREEN}$DONE${RESET_COLOR}"
}

function st.success() {
    local MSG="${1:-[SUCCESS]}"

    echo "${ST_SUCCESS}${BOLD}${GREEN}${MSG}${RESET_COLOR}${OFFBOLD}"
}

function st.nothing() {
    local MSG="${1:-[NOTHING TO DO]}"
    echo "${ST_NOTHING}${DOING_MSG:-} : ${GREEN}${MSG}${RESET_COLOR}"
}

function st.skipped() {
    local MSG="${1:-[SKIPPED]}"
    echo "${ST_SKIPPED}${DOING_MSG:-} : ${BLUE_CYAN}${MSG}${RESET_COLOR}"
}

function st.warn() {
    echo "${ST_WARN}${BOLD}${YELLOW}$1${RESET_COLOR}${OFFBOLD}"
}

function st.fail() {
    local MSG="${1:-[FAILED]}"
    echo -e "${ST_FAIL}${DOING_MSG:-} : ${RED}$MSG${RESET_COLOR}"
    false
}

function st.abort() {
    local MSG="${1:-[ABORTED]}"
    echo -e "${ST_ABORT}${DOING_MSG:-} : ${BOLD}${RED}${MSG}${RESET_COLOR}${OFFBOLD}\n"
    false

    exit 1
}

function st.do() {
    local -a cmd=("$@")
    echo "${ST_DO}${GRAY_LIGHT}${cmd[*]}${RESET_COLOR}"
    "${cmd[@]}"
}

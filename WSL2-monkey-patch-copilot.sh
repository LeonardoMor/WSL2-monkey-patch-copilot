#!/usr/bin/env bash

_VSCODEDIR=~/".vscode-server/extensions"
_COPILOTDIR="$(find "${_VSCODEDIR}" -maxdepth 1 -type d -name "github.copilot-[1-9]*" | sort -V | tail -1)"
_COPILOTCHATDIR="$(find "${_VSCODEDIR}" -maxdepth 1 -type d -name "github.copilot-chat-[0-9]*" | sort -V | tail -1)"
UNDO=0

patch (){
    local _EXTENSIONFILEPATH="$1/dist/extension.js"
    if [[ -f "$_EXTENSIONFILEPATH" ]]; then
        printf "Applying 'rejectUnauthorized' patches to %s...\nBe sure to restart VS Code.\n" "$_EXTENSIONFILEPATH"
        perl -pi.bak0 -e 's/,rejectUnauthorized:[a-z]}(?!})/,rejectUnauthorized:false}/g' "${_EXTENSIONFILEPATH}"
        sed -i.bak1 's/d={...l,/d={...l,rejectUnauthorized:false,/g' "${_EXTENSIONFILEPATH}"
    else
        echo "Couldn't find the extension.js file, please verify paths and try again..."
    fi
}

undo (){
    local _EXTENSIONFILEPATH="$1/dist/extension.js"
    if [[ -f "$_EXTENSIONFILEPATH" ]]; then
        printf "Undoing 'rejectUnauthorized' patches to %s...\nBe sure to restart VS Code.\n" "$_EXTENSIONFILEPATH"
        mv "${_EXTENSIONFILEPATH}.bak0" "${_EXTENSIONFILEPATH}"
    else
        echo "Couldn't find the extension.js file, please verify paths and try again..."
    fi
}

# Parsing options
while getopts ":hu" opt; do
    case $opt in
        h)
            echo "Usage: $0 [-h]"
            echo "  -h  Show this help message"
            exit 0
            ;;
        u)
            UNDO=1
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -eq 0 ]]; then
    printf "Indicate what you want to patch.\n" >&2
    help
    exit 1
fi

# Main logic
for c do
    case $c in
        copilot)
            if [[ $UNDO -eq 0 ]]; then
                patch "$_COPILOTDIR"
            else
                undo "$_COPILOTDIR"
            fi
            ;;
        chat)
            if [[ $UNDO -eq 0 ]]; then
                patch "$_COPILOTCHATDIR"
            else
                undo "$_COPILOTCHATDIR"
            fi
            ;;
        *)
            echo "Invalid Argument: $c" >&2
            exit 1
            ;;
    esac
done

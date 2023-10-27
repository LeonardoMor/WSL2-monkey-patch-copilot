#!/usr/bin/env bash

_VSCODEDIR=~/".vscode-server/extensions"
_COPILOTDIR="$(find "${_VSCODEDIR}" -maxdepth 1 -type d -name "github.copilot-[1-9]*" | sort -V | tail -1)"
_COPILOTCHATDIR="$(find "${_VSCODEDIR}" -maxdepth 1 -type d -name "github.copilot-chat-[0-9]*" | sort -V | tail -1)"

patch (){
    local _EXTENSIONFILEPATH="$1/dist/extension.js"
    if [[ -f "$_EXTENSIONFILEPATH" ]]; then
        printf "Found Copilot Extension, applying 'rejectUnauthorized' patches to %s...\n" "$_EXTENSIONFILEPATH"
        perl -pi.bak0 -e 's/,rejectUnauthorized:[a-z]}(?!})/,rejectUnauthorized:false}/g' "${_EXTENSIONFILEPATH}"
        sed -i.bak1 's/d={...l,/d={...l,rejectUnauthorized:false,/g' "${_EXTENSIONFILEPATH}"
    else
        echo "Couldn't find the extension.js file for Copilot, please verify paths and try again or ignore if you don't have Copilot..."
    fi
}

# for path in "$_COPILOTDIR" "$_COPILOTCHATDIR"; do
for path in "$_COPILOTCHATDIR"; do
    patch "$path"
done

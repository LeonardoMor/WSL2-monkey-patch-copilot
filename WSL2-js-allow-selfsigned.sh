#!/usr/bin/env bash

# WSL2-js-allow-selfsigned.sh
# I got weird errors when using Copilot Chat from repos on WSL2 on Windows 11. See https://github.com/microsoft/vscode-copilot-release/issues/439
# Installing VS Code Insiders and the latest pre-release versions of Copilot and Copilot Chat gives better error messages, such as
#   2023-10-27T23:21:56.713Z [ERROR] [extension] Error on conversation request: (SR) self-signed certificate in certificate chain
# Turns out, that's a NodeJS thing. There's a workaround here: https://stackoverflow.com/a/75239728/7830232
# This script does just that.
#
# Leonardo Mora Castro
# October, 2023

_HOSTNAME="$(hostname)"
_CERTDIR=/etc/ssl/certs

help() {
    cat <<EOF
Usage: $0 [-h] [-u] [rcfile]

This script adds self-signed certificates to the NODE_EXTRA_CA_CERTS environment variable, allowing NodeJS to make HTTPS requests to servers with self-signed certificates.

If no rcfile is specified, the script will try to detect the user's shell and use the appropriate rc file (either ~/.bashrc or ~/.zshrc).

Options:
  -h    Show this help message and exit.
  -u    Undo changes made by a previous run of the script.

Examples:
  $0
  $0 ~/.bashrc
  $0 -u
EOF
}

undo() {
    if [[ -f "$_SRC.bak" ]]; then
        printf "Undoing changes to %s...\n" "$_SRC"
        mv "$_SRC.bak" "$_SRC"
        exit 0
    else
        echo "Couldn't find the backup file, please verify paths and try again..." >&2
        exit 1
    fi
}

# Parsing options
while getopts ":hu" opt; do
    case "$opt" in
    h)
        help
        exit 0
        ;;
    u)
        _UNDO=1
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        help
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

if ((_UNDO == 1)); then
    undo
fi

# We'll know some shell rcs. But if the user spcifies an argument, we'll use that instead as the rc path.
if [[ $1 ]]; then
    _SRC="$1"
else
    case "$SHELL" in
    */bash) _SRC=~/.bashrc ;;
    */zsh) _SRC=~/.zshrc ;;
    *)
        printf "Unknown shell: %s. Please specify the path to your shell rc file as an argument.\n" "$SHELL" >&2
        help
        exit 1
        ;;
    esac
fi

# Dump the certificates for a connection to GitHub Copilot API
awk --assign=hostname="$_HOSTNAME" --source='
    /-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{if(/-----BEGIN CERTIFICATE-----/){a++}
    out="/tmp/hostname"a".crt"; print >out}' -- <(echo "" | openssl s_client -showcerts -connect api.githubcopilot.com:443 2>/dev/null)
mkdir -p "$_CERTDIR"
# Make them pem files, find the self-signed ones and save them
for i in "/tmp/$_HOSTNAME"*.crt; do
    openssl x509 -in "$i" -out "${i%.*}.pem" -outform PEM
    if grep -oqw OK <(openssl verify -verbose -CAfile "${i%.*}.pem" "${i%.*}.pem"); then
        cp -v "${i%.*}.pem" "$_CERTDIR"
        _SELFSIGNED+=":${_CERTDIR}/${i%.*}.pem"
    fi
done
# Do the thing
printf "Adding self-signed certificates to NODE_EXTRA_CA_CERTS and exporting the variable in %s. Be sure to restart your shell.\n" "$_SRC"
sed -i.bak -En '
/^export NODE_EXTRA_CA_CERTS=/!{
p
${ x; /export NODE_EXTRA_CA_CERTS=/!a\
export NODE_EXTRA_CA_CERTS='"$_SELFSIGNED"'\

q
}
}
/^(export NODE_EXTRA_CA_CERTS=)(.*)/{ s||\1\2:'"$_SELFSIGNED"'|p; h; }' -- "$_SRC"

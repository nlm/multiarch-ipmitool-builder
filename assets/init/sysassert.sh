#!/bin/sh

set -eu

get_kernel_cmdline_argument()
{
    local elt arg
    arg="$1"
    set -- $(cat /proc/cmdline)
    for elt in "$@"; do
        case "$elt" in
            "${arg}"=*)
                echo "${elt#${arg}=}"
                return 0
            ;;
            "${arg}")
                return 0
            ;;
        esac
    done
    return 1
}

sysassert_model="$(get_kernel_cmdline_argument sysassert_profile)"
tftp_server="$(cat /run/dhcp/siaddr)"

if [ -z "$tftp_server" ]
then
    echo "no tftp server address available"
    echo "check that the DHCP server sends the required attributes"
    echo "in the DHCP response"
    exit 1
fi

if [ -n "$sysassert_model" ]
then
    PROFILE_FILE="/etc/sysassert/profiles/${sysassert_model}.yaml"
    tftp -g -l "$PROFILE_FILE" -r "sysassert/profiles/${sysassert_model}.yaml" "$tftp_server" 2>/dev/null
    if [ ! -f "$PROFILE_FILE" ]; then
        echo "sysassert profile not available"
        exit 1
    fi
    sysassert validate "$PROFILE_FILE" || true
    sysassert validate "$PROFILE_FILE" >"/run/httpd/result.txt" 2>&1 || true
fi

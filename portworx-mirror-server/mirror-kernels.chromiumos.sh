#!/bin/bash
# ^^ requires bash because save_error() calls bash_stack_trace,
# which uses bash-specific command "caller".

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
mkdir -p ${mirrordir}
cd ${mirrordir} || exit $?

mirrordir=/home/ftp/mirrors


#arch=i386
arch=amd64

TIMESTAMPING=--timestamping
#TIMESTAMPING=--no-clobber

is_string_in_colon_separated_list()
{
    local match="$1"
    local list="$2"
    local word

    (
        IFS=:
        for word in $list ; do
            if [[ ".$word" = ".$match" ]] ; then
                exit 0
            fi
        done
        exit 1
    )
}

add_to_path()
{
    local dir
    for dir in "$@" ; do
        if ! is_string_in_colon_separated_list "$dir" "$PATH" ; then
            PATH="${dir}:${PATH}"
        fi
    done
}

install_depot_tools() {
    # From http://dev.chromium.org/developers/how-tos/install-depot-tools :
    mkdir -p /home/ftp/mirrors/git/https/chromium.googlesource.com/chromium/tools
    ( cd /home/ftp/mirrors/git/https/chromium.googlesource.com/chromium/tools &&
      git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git )

    add_to_path /home/ftp/mirrors/git/https/chromium.googlesource.com/chromium/tools/depot_tools
    export PATH
}

mirror_chromiumos() {
    # From http://www.chromium.org/chromium-os/quick-start-guide:

    mkdir -p /home/ftp/mirrors/git/https/chromium.googlesource.com
    cd /home/ftp/mirrors/git/https/chromium.googlesource.com || return $?

    install_depot_tools

    # cd ${SOURCE_REPO}
    repo init -u https://chromium.googlesource.com/chromiumos/manifest.git

    # Optional: Make any changes to .repo/local_manifests/local_manifest.xml before syncing
    repo sync --force-sync
}

mirror_chromiumos_kernels() {
    # From http://www.chromium.org/chromium-os/quick-start-guide:
    local common="chromium.googlesource.com/chromiumos/third_party"
    local parent="/home/ftp/mirrors/git/https/${common}"
    local dir="${parent}/kernel"

    mkdir -p "$parent"
    cd "$parent" || return $?

    git clone https://${common}/kernel ||
	(cd kernel && git pull) ||
	return $?
}

mirror_chromiumos_kernels

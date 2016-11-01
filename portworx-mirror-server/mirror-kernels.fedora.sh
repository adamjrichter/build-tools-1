#!/bin/sh

#arch=i386
arch=x86_64

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
cd ${mirrordir} || exit $?
mkdir -p ${mirrordir}

# TIMESTAMPING=--timestamping
TIMESTAMPING='--no-clobber --no-use-server-timestamps'
#QUIET=--quiet
QUIET=

mirror_ncsu_edu() {
    local top_url=http://ftp.linux.ncsu.edu/pub/fedora/linux/releases/
    local top_dir=$(url_to_dir "$top_url")

    wget $(QUIET) --protocol-directories --force-directories \
	  "${top_url}"

    extract_subdirs < "$top_dir/index.html" |
	egrep '^[0-9]' |
	sed "s|^|${top_url}|;s|\$|/Everything/x86_64/os/Packages/k/|" |
	xargs wget $(QUIET) --no-parent ${TIMESTAMPING} -e robots=off \
	 --protocol-directories --force-directories --recursive --level=1 \
	 --accept-regex="/(index.html)|(kernel-.*headers.*\.rpm)"

    # FIXME.  The following regular expresion might filter out kernels before
    # 3.10.  It is modified from one that was not working, but maybe this
    # version might work.
    #
    # --accept-regex="/(index.html)|(kernel-(.*-)?headers-${above_3_9_regexp}(.*-.*-.*)?\..*\.rpm)"
}

mirror_ncsu_edu

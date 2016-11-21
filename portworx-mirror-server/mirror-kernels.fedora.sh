#!/bin/bash
# ^^ requires bash because save_error() calls bash_stack_trace,
# which uses bash-specific command "caller".

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

error_code=0

mirror_ncsu_edu() {
    local top_url=http://ftp.linux.ncsu.edu/pub/fedora/linux/releases/
    local top_dir=$(url_to_dir "$top_url")

    rename_bad_rpm_files "$top_dir"

    wget ${QUIET} --protocol-directories --force-directories \
	  "${top_url}"
    save_error

    extract_subdirs < "$top_dir/index.html" |
	egrep '^[0-9]' |
	sed "s|^|${top_url}|;s|\$|/Everything/x86_64/os/Packages/k/|" |
	xargs wget ${QUIET} --no-parent ${TIMESTAMPING} -e robots=off \
	 --protocol-directories --force-directories --recursive --level=1 \
	 --accept-regex="/(index.html)|(kernel-devel.*\.rpm)"

	 # This version would add kernel-xxx-heades, but currently only
	 # matches kernel-cross-headers on ftp.linux.ncsu.edu:
	 # --accept-regex="/(index.html)|(kernel-.*devel.*\.rpm)"
	 
    # FIXME.  The following regular expresion might filter out kernels before
    # 3.10.  It is modified from one that was not working, but maybe this
    # version might work.
    #
    # --accept-regex="/(index.html)|(kernel-(.*-)?devel-${above_3_9_regexp}(.*-.*-.*)?\..*\.rpm)"
    save_error
}

mirror_ncsu_edu
save_error
exit $error_code

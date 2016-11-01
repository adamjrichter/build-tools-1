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

versions_above_3_9 () {
    egrep '^v(4|3\.[1-9][0-9]).*/$'
}

mirror_el_repo() {
    local top_url=http://elrepo.org/linux/kernel/
    local top_dir=$(url_to_dir "$top_url")

    wget --no-parent ${TIMESTAMPING} -e robots=off \
	 --protocol-directories --force-directories --recursive \
	 --accept-regex='.*/(index.html)?$' \
	 ${top_url}

    for dir in ${top_dir}/*/${arch}/RPMS/ ; do
	echo ''
	extract_subdirs < $dir/index.html |
	    egrep "^kernel-.*headers-.*.${arch}.rpm$" |
	    subdirs_to_urls http://${dir#http/}
    done |
	xargs -- wget --no-parent ${TIMESTAMPING} \
	      --protocol-directories --force-directories
}

mirror_el_repo

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

    wget --quiet --no-parent ${TIMESTAMPING} -e robots=off \
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

mirror_mirror_centos_org() {
    local top_url=http://mirror.centos.org/centos/
    local top_dir=$(url_to_dir "$top_url")

    wget --quiet --protocol-directories --force-directories \
	  "${top_url}"

    extract_subdirs < "$top_dir/index.html" |
	egrep '^[0-9]' |
	sed "s|^|${top_url}|;s|\$|/os/x86_64/Packages/|" |
	xargs wget --quiet --no-parent ${TIMESTAMPING} -e robots=off \
	 --protocol-directories --force-directories --recursive --level=1 \
	 --accept-regex="/(index.html)|(kernel-.*headers.*\.rpm)"

    # FIXME.  The following URL, that should filter out kernels before
    # 3.10, is not working:
    #
    # --accept-regex="/(index.html)|(kernel-${above_3_9_regexp}(.*-)?headers(.*-.*-.*)?\..*\.rpm)"
}


# TODO? mirror vault.centos.org, but it only contains source RPM's.  The
# kernel-headers RPM's that we use are apparently non-source RPM's
# generated from kernel source RPM's.

# mirror_vault_centos_org
mirror_mirror_centos_org
mirror_el_repo

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

error_code=0

versions_above_3_9 () {
    egrep '^v(4|3\.[1-9][0-9]).*/$'
}

mirror_el_repo() {
    local top_url=http://elrepo.org/linux/kernel/
    local top_dir=$(url_to_dir "$top_url")

    local rpm_arch

    case "$arch" in
	amd64 ) rpm_arch="x86_64" ;;
	* ) rpm_arch="$arch" ;;
    esac

    rename_bad_rpm_files "$top_dir"

    # For now, do not include "--no-clobber" in this top level wget.
    # Pull new index.html files every time.  Otherwise, the files do
    # not get updated.  FIXME: Confirm that  timestamps are not
    # supported by the elrepo web server.
    #
    wget --quiet --no-parent -e robots=off \
	 --protocol-directories --force-directories --recursive \
	 --accept-regex='.*/(index.html)?$' \
	 ${top_url}

    save_error

    for dir in ${top_dir}/*/${rpm_arch}/RPMS/ ; do
	echo ''
	extract_subdirs < $dir/index.html |
	    egrep "^kernel-.*devel-.*.${rpm_arch}.rpm$" |
	    subdirs_to_urls http://${dir#http/}
    done |
	xargs -- wget --quiet --no-parent ${TIMESTAMPING} \
	      --protocol-directories --force-directories

    save_error
}

mirror_mirror_centos_org() {
    local top_url=http://mirror.centos.org/centos/
    local top_dir=$(url_to_dir "$top_url")

    rename_bad_rpm_files "$top_dir"

    wget --quiet --protocol-directories --force-directories "${top_url}"

    extract_subdirs < "$top_dir/index.html" |
	egrep '^[1-9][0-9]*\.[0-9]+' |
	sed "s|^|${top_url}|;s|\$|/os/x86_64/Packages/|" |
	xargs wget --quiet --no-parent ${TIMESTAMPING} -e robots=off \
	 --protocol-directories --force-directories --recursive --level=1 \
	 --accept-regex="/(index.html)|(kernel-.*devel.*\.rpm)"

    # FIXME.  The following regular expresion might filter out kernels before
    # 3.10.  It is modified from one that was not working, but maybe this
    # version might work.
    #
    # --accept-regex="/(index.html)|(kernel-(.*-)?headers-${above_3_9_regexp}(.*-.*-.*)?\..*\.rpm)"

    save_error
}


# TODO? mirror vault.centos.org, but it only contains source RPM's.  The
# kernel-headers RPM's that we use are apparently non-source RPM's
# generated from kernel source RPM's.

# mirror_vault_centos_org
mirror_mirror_centos_org
save_error

mirror_el_repo
save_error

exit $error_code

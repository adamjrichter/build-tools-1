#!/bin/sh

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
mkdir -p ${mirrordir}
cd ${mirrordir} || exit $?

mirrordir=/home/ftp/mirrors


#arch=i386
arch=amd64

#TIMESTAMPING=--timestamping
TIMESTAMPING=--no-clobber

above_3_9_regexp='(3\.[1-9][0-9]|[4-9]|[1-9][0-9])'

newlines_around_angle_brackets() {
    sed 's/</\'$'\n''</g;s/>/>\'$'\n''/g;'
}

# I think there is a perl program named extract-urls that will do thisb better.
extract_subdirs() {
    newlines_around_angle_brackets |
	egrep '^<a href="' | sed 's/^[^"]*"//;s/"[^"]*$//'
}

versions_above_3_9 () {
    egrep "^v${above_3_9_regexp}.*/\$"
}

subdirs_to_urls() {
    local top_url="$1"

    while read subdir ; do
        echo "$top_url/$subdir"
    done
}

echo_one_per_line() {
    local word
    for word in "$@" ; do
	echo "$word"
    done
}

get_subdir_index_files() {
    local top_url="$1"
    echo_one_per_line $subdirs |
        subdirs_to_urls "${top_url}"  |
        xargs -- wget ${TIMESTAMPING} --quiet --protocol-directories \
	      --force-directories --accept=index.html --recursive
}

remove_index_html_mirror_files() {
    local url dir
    for url in "$@" ; do
	case "$url" in
	    *://* )
		dir=$(url_to_dir "$url")
		rm -f "$dir/index.html" || true ;;
	esac
    done
}

mirror_one_dir() {
    if [ ".${TIMESTAMPING}" = ".--no-clobber" ] ; then
	remove_index_html_mirror_files "$@"
    fi

    wget ${TIMESTAMPING} --quiet --protocol-directories --force-directories \
	 --recursive --level=1 \
	 --accept-regex=".*/index.html|(linux-headers-${above_3_9_regexp}.*(${arch}|all)\.deb)\$" \
	 "$@"
}

mirror_subdirs() {
    local top_url="$1"
    local top_dir
    top_dir=$(url_to_dir "$top_url")
    rm -f ${top_dir}/index.html
    wget --quiet --force-directories --protocol-directories ${top_url}/

    # FIXME.  This breaks for subdirectory names containing spaces.
    subdirs=$(extract_subdirs <  ${top_dir}/index.html | versions_above_3_9)

    get_subdir_index_files "$top_url"

    # TODO: Change "image" to "headers"
    for subdir in $subdirs ; do
	#which=image
	which=headers
	subdir_no_slash=${subdir%/}
	extract_subdirs < "${top_dir}/$subdir/index.html" |
	    egrep "linux-${which}-[0-9].*_(${arch}|all).deb" |
	    subdirs_to_urls "${top_url}/${subdir_no_slash}"
    done |
	xargs -- wget ${TIMESTAMPING} --quiet \
	      --protocol-directories --force-directories
}

mirror_one_dir "http://security.ubuntu.com/ubuntu/pool/main/l/linux/"
mirror_subdirs "http://kernel.ubuntu.com/~kernel-ppa/mainline"
# TODO?: mirror https://bugs.launchpad.net/~canonical-kernel-team/+archive/ubuntu/ppa
# TODO?: Investigate linux-headers-4.2.0-36-generic_4.2.0-36.41_amd64.deb found by Ankit on https://bugs.launchpad.net/~canonical-kernel-team/+archive/ubuntu/ppa/+build/9593535

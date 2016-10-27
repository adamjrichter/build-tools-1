#!/bin/sh

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
mkdir -p ${mirrordir}
cd ${mirrordir} || exit $?

mirrordir=/home/ftp/mirrors


url_dir=kernel.ubuntu.com/~kernel-ppa/mainline
top_url=http://$url_dir
top_dir=http/$url_dir

#arch=i386
arch=amd64

#TIMESTAMPING=--timestamping
TIMESTAMPING=--no-clobber

newlines_around_angle_brackets() {
    sed 's/</\'$'\n''</g;s/>/>\'$'\n''/g;'
}

# I think there is a perl program named extract-urls that will do thisb better.
extract_subdirs() {
    newlines_around_angle_brackets |
	egrep '^<a href="' | sed 's/^[^"]*"//;s/"[^"]*$//'
}

versions_above_3_9 () {
    egrep '^v(4|3\.[1-9][0-9]).*/$'
}

subdirs_to_urls() {
    local top_url="$1"

    while read subdir ; do
        echo "$top_url/$subdir"
    done
}

rm -f ${top_dir}/index.html
wget --force-directories --protocol-directories ${top_url}/

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
        xargs -- wget ${TIMESTAMPING} \
	      --protocol-directories --force-directories \
	      --accept=index.html --recursive
}

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
    xargs -- wget ${TIMESTAMPING} --protocol-directories --force-directories

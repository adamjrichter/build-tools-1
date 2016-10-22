#!/bin/sh

#arch=i386
arch=x86_64

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
cd ${mirrordir} || exit $?
mkdir -p ${mirrordir}

# TIMESTAMPING=--timestamping
TIMESTAMPING='--no-clobber --no-use-server-timestamps'

top=elrepo.org/linux/kernel/
top_dir=http/$top
top_url=http://$top

do_wget() {
    wget --no-parent ${TIMESTAMPING} "$@"
}

newlines_around_angle_brackets() {
    sed 's/</\'$'\n''</g;s/>/>\'$'\n''/g;'
}

# I think there is a perl program named extract-urls that will do this better.
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

echo_one_per_line() {
    local word
    for word in "$@" ; do
	echo "$word"
    done
}

cd /home/ftp/mirrors || exit $?

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

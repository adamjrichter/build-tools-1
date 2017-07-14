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

list_amazon_linux_versions() {
    local endyear=$(date +%Y)
    local year

    # The first Amazon Linux release appears to have been 2011.09.
    echo "2011.09"

    year=2012
    while [ "$year" -le "$endyear" ] ; do
	echo "$year.03"
	echo "$year.09"
	year=$((year + 1))
    done
}

list_amazon_linux_urls() {
    # Amazon releases are four_digit_year.two_digit_month, where four_digit
    # year starts at 2011, and two_digit_month is 03 or 09.
    local confdir=/tmp/amazon-config.$$
    local release_ver repos
    
    rm -rf "$confdir"
    cp -apr /home/pwxmirror/mirror-scripts/from_amazon_linux "$confdir"
    ( egrep -v '^(reposdir|installroot|releasever)=' \
	    < /home/pwxmirror/mirror-scripts/from_amazon_linux/etc/yum.conf
      echo "installroot=${confdir}/"  # Prefix directory of etc/yum/vars.
      echo "reposdir=${confdir}/etc/yum.repos.d/" ) > "${confdir}/etc/yum.conf"

    repos=$(cat "$confdir/etc/yum.repos.d"/*.repo |
		   egrep '^\['  |
		   sed 's/^\[/ --repo=/;s/\]$//')
    list_amazon_linux_versions |
	while read release_ver ; do
	    # FIXME.  This seems to look for the latest release anyhow.
	    echo "$release_ver" > "$confdir/etc/yum/vars/releasever"
	    echo "releasever=${release_ver}" >> "$confdir/etc/yum.conf"
	    rm -rf "${confdir}/download"
	    mkdir -p "${confdir}/download"
	    reposync --download_path="${confdir}/download" --urls --source \
		     --config="$confdir/etc/yum.conf" $repos --quiet \
		     2> /dev/null
	done |
	egrep 'kernel-devel.*\.rpm|/SRPMS/kernel-.*.src.rpm'

    # The following filter should eliminate paths to the same filename:
    # sort --reverse |
    # awk -F/ '{paths[$1] = $0;} END {for (i in paths) {print paths[i];}}'

    rm -rf "$confdir"
}

mirror_amazon_linux() {
    list_amazon_linux_urls |
	sort -u |
	wget --protocol-directories --force-directories --no-clobber \
	     --quiet --input-file=-

    save_error
}

mirror_amazon_linux
save_error
exit $error_code

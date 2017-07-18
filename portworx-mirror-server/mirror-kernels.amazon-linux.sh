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
amzn_confdir_template=/home/pwxmirror/mirror-scripts/from_amazon_linux

# TIMESTAMPING=--timestamping
TIMESTAMPING='--no-clobber --no-use-server-timestamps'
#QUIET=--quiet
QUIET=

error_code=0

amzn_list_versions() {
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

amzn_init_confdir() {
    local confdir="$1"

    rm -rf "$confdir" "/var/tmp/yum-$(whoami)-"*
    cp -apr "${amzn_confdir_template}" "$confdir"
    mkdir -p "${confdir}/var/log" "${confdir}/var/cache/yum"
    sed "s|=/|=${confdir}/|" \
            < ${amzn_confdir_template}/etc/yum.conf |
    ( egrep -v '^(reposdir|installroot|releasever)='
      echo "installroot=${confdir}/"  # Prefix directory of etc/yum/vars.
      echo "reposdir=${confdir}/etc/yum.repos.d/" ) \
	> "${confdir}/etc/yum.conf"
}

amzn_list_urls() {
    # Amazon releases are four_digit_year.two_digit_month, where four_digit
    # year starts at 2011, and two_digit_month is 03 or 09.
    local confdir=/tmp/amazon-config.$$
    local release_ver repos

    repos=$(cat "${amzn_confdir_template}/etc/yum.repos.d"/*.repo |
		   egrep '^\['  |
		   sed 's/^\[/ --repo=/;s/\]$//' )

    amzn_list_versions | while read release_ver ; do

        amzn_init_confdir "${confdir}"

	# FIXME.  This seems to look for the latest release anyhow.
	echo -n "$release_ver" > "$confdir/etc/yum/vars/releasever"
	echo "releasever=${release_ver}" >> "$confdir/etc/yum.conf"
	rm -rf "${confdir}/download" "${confdir}/var/lib/yum"
	mkdir -p "${confdir}/download"
	# Apparently "--source" only works when repos are specified.  Also,
	# reposync will abort if an unknown repo is specified.  So, run
	# reposync separately on echo repo.
	for repo in $repos ; do
	    reposync --download_path="${confdir}/download" --urls --source \
		     --config="${confdir}/etc/yum.conf" $repo
	done
#	--quiet 2> /dev/null
    done |
	egrep 'kernel-devel.*\.rpm|/SRPMS/kernel-.*.src.rpm'

    # The following filter should eliminate paths to the same filename:
    # sort --reverse |
    # awk -F/ '{paths[$1] = $0;} END {for (i in paths) {print paths[i];}}'

    rm -rf "$confdir"
}

mirror_amazon_linux() {
    amzn_list_urls |
	sort -u |
	wget --protocol-directories --force-directories --no-clobber \
	     --input-file=-

    save_error
}

mirror_amazon_linux
save_error
exit $error_code

#!/bin/bash
# ^^ requires bash because save_error() calls bash_stack_trace,
# which uses bash-specific command "caller".

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
mkdir -p ${mirrordir}
cd ${mirrordir} || exit $?

mirrordir=/home/ftp/mirrors


#arch=i386
arch=amd64

TIMESTAMPING=--timestamping
#TIMESTAMPING=--no-clobber

mirror_coreos() {
    local release="$1"
    local prefix="https://${release}.release.core-os.net"
    
    wget ${TIMESTAMPING} --quiet --protocol-directories \
	 --force-directories --accept=index.html --recursive \
	 "${prefix}/"

    wget ${TIMESTAMPING} --quiet --protocol-directories --recursive \
	 --force-directories \
	 --accept-regex='.*/(index.html|.*\.iso)?$' \
	 "${prefix}/${arch}-usr/"
}

mirror_coreos stable
# mirror_coreos alpha
# mirror_coreos beta

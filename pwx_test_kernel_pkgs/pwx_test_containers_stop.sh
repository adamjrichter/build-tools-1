#!/bin/bash
# ^^^^^^^^^ bash because it uses "[["
# Stops all Linux containers that pwx_test_containers might have started.

scriptsdir=$PWD

usage() {
    echo "Usage: pwx_test_containers_stop.sh [--distribution=dist] [--containers=container_system] [--releases=releases]"
    echo "    Stops all containers used by pwx_test_kernel_pkgs for the"
    echo "    specified operating system distribution releases."
    echo ""
}

arch=amd64
distro=ubuntu
distro_releases=""
container_system=lxc


. ${scriptsdir}/container_driver.sh
. ${scriptsdir}/distro_driver.sh

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--arch=* ) arch=${1#--arch=} ;;	  # Unused, but allow it for now.
	--containers=* ) container_system=${1#--containers=} ;;
	--distribution=* ) distro=${1#--distribution=} ;;
	--releases=* ) distro_release=${1#--releases=} ;;
	--* ) usage >&2 ; exit 1 ;;
	* ) break ;;
    esac
    shift
done

main()
{
    local release releases

    if [[ -n "$distro_releases" ]] ; then
	releases=$(echo "$distro_releases" | sed 's/,/ /g')
    else
	releases=$(get_dist_releases)
    fi

    for release in $releases ; do
	stop_container --release="$release"
    done
}

main

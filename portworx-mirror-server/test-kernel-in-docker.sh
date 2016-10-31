#!/bin/sh

echo "$0 $*" >&2

usage() {
	echo "Usage: test-kernels-docker.sh distribution pxfuse_directory log_dir [kernel-header-pkg kernel-header-pkg...]"
	echo "   \"distribution\" must currently be one of: centos debian ubuntu"
}

if [ $# -lt 2 ] ; then
    usage >&2
    exit 1
fi

distribution=$( echo "$1" | tr A-Z a-z)
container_name="pwx_test_${distribution}"
pxfuse_dir="$2"
results_log_dir="$3"
shift 3

case "$distribution" in
    centos          ) pkg_fetcher="yum"     ; pkg_installer="rpm" ;;
    debian | ubuntu ) pkg_fetcher="apt-get" ; pkg_installer="dpkg" ;;
    *               ) echo "Unknown distribution $distribution." >&2 ; exit 1 ;;
esac

in_container() {
    docker exec --interactive "$docker_pid" "$@"
}

get_kernel_headers_pkg_names() {
    local pkg
    for pkg in "$@" ; do
        # FIXME: Does this work for rpm?
        set $( $pkg_installer --info "$first_pkg" | egrpe '^ Package: ' )
        echo "$2"
    done
}

get_kernel_headers_dir() {
    local debfile="$1"
    $pkg_installer --contents "$debfile" |
	egrep ^d |
	awk '{print $NF}' |
	egrep ^./usr/src/linux-headers- |
	sed 's|^\.\?\(/usr/src/linux-headers-[^/]*\)/.*$|\1|' |
	uniq
}

cleanup() {
    local pkgs="$(get_kernel_headers_pkg_names)"
    set +e
    if [ -n "$pkgs" ] ; then
	in_container $pkg_installer --remove $pkgs
    fi
    in_container rm -rf "${container_tmpdir}"
    # docker stop "$docker_pid"
    # docker rm --volumes=true "$docker_pid"
}

host_tmpdir=/tmp/test-kernels.$$
container_tmpdir=/tmp/test-kernels.$$

# STUB?: Log results somewhere instead of stdout and stderr?

set_up_container() {
    local id=$(docker ps -a --format "{{.ID}}" --filter name="${container_name}")
    if [ -n "$id" ] ; then
	docker start "$id"
	docker_pid="$id"
	return 0
    else
	docker pull $distribution
        docker_pid=$(docker run --interactive --name "${container_name}" --detach "$distribution" bash)
	in_container $pkg_fetcher update
	# ^^^ Skip this for binary reproducibility ??

	in_container $pkg_fetcher install -y autoconf gcc g++ make tar
	case "$distribution" in
	    ubuntu|debian ) in_container $pkg_fetcher install -y libssl1.0 ;;
	esac
    fi
	
}

trap cleanup EXIT

set_up_container

in_container mkdir -p "$container_tmpdir/pxfuse_dir" "$container_tmpdir/header_pkgs"
( cd "$pxfuse_dir" && tar c . ) |
    in_container tar -C "${container_tmpdir}"/pxfuse_dir -xp

if [ $# -gt 0 ] ; then
    for filename in "$@" ; do
	real=$(realpath $filename)
	dirname=${real%/*}
	basename=${real##*/}
	tar -C "$dirname" -c -- "$basename" | in_container tar -C "${container_tmpdir}/header_pkgs" -xpv
    done
    in_container sh -c -- "${pkg_installer} --install --force-all ${container_tmpdir}/header_pkgs/*"
fi

in_container sh -c "cd ${container_tmpdir}/pxfuse_dir && autoreconf && ./configure"
in_container make -C ${container_tmpdir}/pxfuse_dir \
	     KERNELPATH=$(get_kernel_headers_dir "$@")
result=$?
echo "test-kernels.docker.sh: build_exit_code=$result"
if [ "$result" = 0 ] ; then
    # Retrieve px.ko file:
    in_container tar -C "${container_tmpdir}/pxfuse_dir" -c px.ko |
	( tar -C "${results_log_dir}" -xpv )
fi

cleanup
exit "$result"	# calls cleanup, so no need for preceeding line, right?

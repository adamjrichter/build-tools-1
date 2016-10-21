#!/bin/sh

set -e -x

usage() {
    echo "Usage: docker-host-test-kernel-build.sh results_dir deb_files"
}

get_portworx_docker_pid() {
	set -- $(docker ps | grep -w portworx/px-dev)
	echo "$1"
}

get_dpkg_name() {
	local debfile="$1"
	set -- $(dpkg --info "$debfile" | egrep '^ Package: ')
	echo "$2"
}

exit_func() {
    echo "AJR exit_func $* called."
    dpkg --remove $pkg_names
    touch -f "${results_dir}/done"
}

if [ $# -lt 2 ] ; then
    usage >&2
    exit 1
fi

results_dir="$1"

if [ -e "${results_dir}/done" ] ; then
    echo "${results_dir}/done exists.  Skipping." >&2
    exit 0
fi

rm -rf "$results_dir"
mkdir -p "$results_dir"
exec > "$results_dir/build.log" 2>&1

shift

# debfiles="$@"

pkg_names=""
for debfile in "$@" ; do
    pkg_name=$(get_dpkg_name "$debfile")
    pkg_names="$pkg_names $pkg_name"
done


portworx_docker_pid=$(get_portworx_docker_pid)
echo $portworx_docker_pid

# Select an architecture-specific debfile:
for debfile in $debfiles ; do
    case "$debfile" in
	*_all.deb ) ;;
	* ) break ;;
    esac
done

usr_src_dir=$(dpkg --contents "$debfile" |
	      egrep ^d |
	      awk '{print $NF}' |
	      egrep ^./usr/src/linux-headers- |
	      sed 's|^\.\?\(/usr/src/linux-headers-[^/]*\)/.*$|\1|' |
	      uniq)

apt-get install module-init-tools

trap exit_func EXIT
dpkg --install "$@"
# docker exec -t -i "$portworx_docker_pid"
set +e
docker exec "$portworx_docker_pid" \
       /usr/bin/make -C /pwx_root/home/px-fuse KERNELPATH=$usr_src_dir

echo "AJR build_exit_code=$?"

docker exec "$portworx_docker_pid" \
       cp /home/px-fuse/px.ko /usr/src/

cp /usr/src/px.ko "${results_dir}/"


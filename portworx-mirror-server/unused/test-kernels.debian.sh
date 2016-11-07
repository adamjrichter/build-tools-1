#!/bin/bash
# set -e -x
set -e

usage() {
    echo "test-kernel.debian.sh [pxfuse_directory]"
}

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh

local_tmp_dir=/tmp/test-kernels.debian.$$
remote_tmp_dir=/tmp/test-portworx-kernels
remote_results_parent_dir=${scriptsdir}/../build-results/debian

target_host=root@localhost
target_port=56
ssh_target="ssh -p $target_port $target_host"
arch=amd64

run_remotely=false

if [ $# -gt 1 ] ; then
    usage >&2
    exit 1
fi

if [ $# -gt 0 ] ; then
    local_pxfuse_src="$1"
else
    local_pxfuse_src=""
fi

cd /home/ftp/mirrors/http/snapshot.debian.org/archive/debian || exit $?

dpkg_file_to_pkg_name()
{
    local filename="$1"
    set -- $(dpkg --info "$filename" | egrep '^ Package: ')
    echo "$2"
}

process_files_remotely()
{
    local remote_results_dir="${remote_results_parent_dir}/${arch_file%.deb}"

    $ssh_target -n -- "rm -rf $remote_tmp_dir ; mkdir -p $remote_tmp_dir"

    scp -p -P $target_port $file $arch_file ${target_host}:${remote_tmp_dir}/

    $ssh_target -n -- \
        "/home/adam/portworx/docker-host-test-kernel-build.sh ${remote_results_dir} ${remote_tmp_dir}/*.deb"
}

process_files_locally()
{
    local result_log_dir="$1"
    shift
    $scriptsdir/test-kernel-in-docker.sh debian "${results_dir}/px-fuse" \
			"$results_log_dir" "$@"
}

process_non_arch_file()
{
        local file="$1"
        local pkg_name dir arch_file log_file results_log_dir results_log_file
	local prefix suffix middle possible_file files

	prefix="${file%-common_*}"
	suffix="${file#*-common_}"

        pkg_name=$(dpkg_file_to_pkg_name "$file")
        dir=${file%/*}

	files=""
	for middle in common all all-${arch} ${arch} ; do
	    possible_file="${prefix}-${middle}_${suffix}"
	    if [[ -e "$possible_file" ]] ; then
		files="$files $possible_file"
		arch_file="$possible_file"
	    fi
	done

	results_log_dir="${results_dir}/${arch_file}"
	if [ -e "$results_log_dir/done" ] ; then
	    echo "$results_log_dir/done already exists.  Skipping." >&2
	    continue
	fi

	mkdir -p "${results_log_dir}"
	results_log_file=$results_log_dir/build.log
        if $run_remotely ; then
            process_files_remotely "$results_log_dir" $files > "$results_log_file" 2>&1
        else
            process_files_locally "$results_log_dir" $files > "$results_log_file" 2>&1
        fi
	touch -f "$results_log_dir/done"
}

set_up_pxdev_quick_start()
{
    if [ ! -e /etc/pwx/config.json ] ; then
        mkdir -p /etc/pwx
        cp $scriptsdir/px-dev/quick-start/config.json /etc/pwx/
    fi
    ( cd $scriptsdir/px-dev/quick-start && docker-compose run portworx -daemon --kvdb=etcd:http://myetcd.example.com:4001 --clusterid=YOUR_CLUSTER_ID --devices=/dev/xvdi > $scriptsdir/../portworx-container.log 2>&1 < /dev/null & sleep 10 )
}

checksum_current_directory() {
    find . \( -name .git -type d -prune \) -o \( -type f -print0 \) |
        sort --zero-terminated |
        xargs --null --no-run-if-empty --max-args=1 md5sum |
        md5sum - |
	sed 's/ .*$//'
}

set_up_pxfuse()
{
    # Sets the global variable $results_dir.
    rm -rf "${local_tmp_dir}"
    mkdir -p "${local_tmp_dir}"
    if [ -n "$pxfuse_src" ] ; then
	cp -apr "$pxfuse_src/." "$local_tmp_dir/px-fuse"
    else
	(cd "$local_tmp_dir" &&
	 git clone https://github.com/portworx/px-fuse.git )
    fi
    pxfuse_checksum=$(cd "$local_tmp_dir/px-fuse" && checksum_current_directory)

    results_dir="${scriptsdir}/../build-results/pxfuse-checksum-${pxfuse_checksum}/debian"

    mkdir -p "$results_dir"
    if [ ! -e "$results_dir/px-fuse" ] ; then
        cp -apr "$local_tmp_dir/px-fuse" "$results_dir/"
    fi
    rm -rf "${local_tmp_dir}"
}


# apt-get install coreutils	# for md5sum
# ^^^ I think coreutils comes preinstalled on all standard Debian images.

set +e

# set_up_pxdev_quick_start
set_up_pxfuse
systemctl start docker
find . -name "linux-headers-*-common_*_${arch}.deb" -type f |
    while read file ; do
        process_non_arch_file "$file" < /dev/null
	# ^^^ Set stdin to /dev/null to prevent the function from reading
	# the results of find (probably by "docker exec").
    done

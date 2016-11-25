# To be sourced by a bash script (bash because this file uses "[[")

# Global variables:
container_name=

# To use LXC containers, for now, the script must be running as superuser.

await_default_route() {
    local count=100
    while [[ $count -gt 0 ]] ; do
	if in_container_lxc ip route | egrep --quiet '^default via ' ; then
	    return 0
	fi
	sleep 0.1
	count=$((count - 1))
    done
    return 1
}

await_dns() {
    local count=100
    while [[ $count -gt 0 ]] ; do
	if in_container_lxc test -e /etc/resolv.conf ; then
	    return 0
	fi
	sleep 0.1
	count=$((count - 1))
    done
    return 1
}

is_container_running() {
    lxc-info --name "$1" | egrep --silent '^State: *RUNNING$'
}

start_container_lxc() {
    local must_initialize
    local release=""

    while [[ $# -gt 0 ]] ; do
	case "$1" in
	    --release=* ) release="${1#--release=}" ;;
	    --* ) echo "start_container_lxc: Unrecognized argument \"$1\"." >&2 ;;
	    -- ) shift ; break ;;
	    * ) break ;;
	esac
	shift
    done

    if [[ -z "$release" ]] ; then
	echo "start_container_lxc: --release=dist_release missing." >&2
	return 1
    fi

    container_name="pwx_test_${distro}_${release}"

    lxc-ls > /dev/null 2>&1 || true
    # ^^^ Removes incompletely initialized containters

    if [[ -e "/var/lib/lxc/${container_name}" ]] ; then
	must_initialize=false
    else
	must_initialize=true
	lxc-create --name "${container_name}" --template download -- \
		     --dist "$distro" --arch "$arch" --release "$release"
    fi

    if ! is_container_running "${container_name}" ; then
        lxc-start --name "${container_name}" --daemon
    fi

    if ! await_default_route ; then

	# Centos 6 has a problem where it (sometimes?) does not get
	# its default route immediately after lxc-create.  Even
	# though doing lxc-start / lxc-start again on the container
	# from the command line makes it recover, doing so from
	# this script does not.  However, running
	# "/etc/initd.network restart" in the Centos 6 container
	# does seem to fix the problem from this script.
	in_container_lxc /etc/init.d/network restart

	await_default_route
    fi

    if ! await_dns ; then
	in_container_lxc tee /etc/resolve.conf < /etc/resolv.conf > /dev/null
    fi

    dist_start_container
    if $must_initialize ; then
	"$@"
    fi
}

stop_container_lxc() {
    # lxc-stop --name "$container_name"
    true
}

in_container_lxc() {
    lxc-attach --name "$container_name" --clear-env \
        --set-var \
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
	--set-var SHELL=/bin/sh \
	--set-var USER=root \
	-- "$@"
}

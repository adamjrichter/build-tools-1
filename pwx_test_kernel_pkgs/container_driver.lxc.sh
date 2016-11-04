# To be sourced by a bash script (bash because this file uses "[[")

# Global variables:
container_name=

# To use LXC containers, for now, the script must be running as superuser.

use_lxc_attach=true

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

    if $use_lxc_attach ; then
	if ! is_container_running "${container_name}" ; then
            lxc-start --name "${container_name}" --daemon
	fi
	await_default_route
	if ! await_dns ; then
	    in_container_lxc tee /etc/resolve.conf \
			     < /etc/resolv.conf > /dev/null
	fi
    fi

    if $must_initialize ; then
	"$@"
    fi
}

stop_container_lxc() {
#    if $use_lxc_attach ; then
#	lxc-stop --name "$container_name"
#    fi
    true
}

in_container_lxc() {
    if $use_lxc_attach ; then
        lxc-attach --name "$container_name" -- "$@"
    else
        lxc-execute --name "$container_name" -- "$@"
    fi
}

# To be sourced by a shell script

# Global variables:
container_name=

# To use LXC containers, for now, the script must be running as superuser.

use_lxc_attach=true

start_container_lxc() {
    local release
    container_name="pwx_test_${distro}"

    apt-get install -y lxc

    case "$distro" in
	ubuntu ) release="xenial" ;;
	debian ) release="jessie" ;;
	centos ) release="Core" ;;
	* )
	    echo "start_container_lxc: Unknown distribution \"${distro}\"." >&2
	    echo "Failing." >&2
	    return 1 ;;
    esac

    if [ ! -e "/var/lib/lxc/${container_name}" ] ; then
	lxc-create --name "${container_name}" --template download -- \
		     --dist "$distro" --arch "$arch" --release "$release"

	"$@"
    fi

    if $use_lxc_attach ; then
        lxc-start --name "${container_name}" --daemon
    fi
}

stop_container_lxc() {
    if $use_lxc_attach ; then
	lxc-stop "$container_name"
    fi
    true
}

in_container_lxc() {
    if $use_lxc_attach ; then
        lxc-attach --name "$container_name" -- "$@"
    else
        lxc-execute --name "$container_name" -- "$@"
    fi
}

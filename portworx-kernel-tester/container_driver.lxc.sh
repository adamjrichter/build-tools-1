# To be sourced by a shell script

# Global variables:
container_name=

# To use LXC containers, for now, the script must be running as superuser.

start_container_lxc() {
    local release
    container_name="pwx_test_${distribution}"

    apt-get install -y lxc

    case "$distribution" in
	ubuntu ) release="xenial" ;;
	debian ) release="jessie" ;;
	centos ) release="Core" ;;
    esac

    if [ ! -e "/var/lib/lxc/${container_name}" ] ; then
	lxc-create --name "${container_name}" --template download -- \
		   --dist "$distribution" --arch "$arch" --release "$release"
	in_container_lxc "$@"
    fi

    # lxc-start --name "${container_name}" --daemon
}

stop_container_lxc() {
    # lxc-stop "$container_name"
    true
}

in_container_lxc() {
    lxc-execute --name "$container_name" -- "$@"
}

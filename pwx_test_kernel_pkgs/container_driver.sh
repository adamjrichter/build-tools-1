# To be sourced by a shell script

container_system=docker	# force this default for now.
. $scriptsdir/container_driver.docker.sh
. $scriptsdir/container_driver.lxc.sh

stop_container() { "stop_container_$container_system" "$@" ; }
in_container() { "in_container_$container_system" "$@" ; }

start_container()
{
    local release=""

    while [[ $# -gt 0 ]] ; do
	case "$1" in
	    --release=* ) release="${1#--release=}" ;;
	    -- ) shift ; break ;;
	    --* ) echo "start_container: Unrecognized argument \"$1\"." >&2 ;;
	    * ) break ;;
	esac
	shift
    done

    if [[ -z "$release" ]] ; then
	release=$(set $(get_dist_releases) ; echo $1)
	if [[ -z "$release" ]] ; then
	    echo "start_container_lxc: Unable to determine default release for distribution \"${distro}\"." >&2
	    echo "Failing." >&2
	    return 1
	fi
    fi

    "start_container_$container_system" --release="$release" "$@"
}


# Trivial implementation for the "none" driver.  You can set the
# container command prefix to be something like "ssh -p some_port some_host"
# implement ssh into a host as a container.

container_command_prefix=
start_container_none() { in_container_none "$@" ; }
stop_container_none() { true ; }
in_container_none() { $container_command_prefix "$@" ; }

# To be sourced by a shell script

container_system=docker	# force this default for now.
. $scriptsdir/container_driver.docker.sh
. $scriptsdir/container_driver.lxc.sh

start_container() { "start_container_$distro" "$@" ; }
stop_container() { "stop_container_$container_system" "$@" ; }
in_container() { "in_container_$container_system" "$@" ; }

start_container_generic()
{
    local release=""
    local distribution="$distro"

    while [[ $# -gt 0 ]] ; do
	case "$1" in
	    --distribution=* ) distribution="${1#--distribution=}" ;;
	    --release=* ) release="${1#--release=}" ;;
	    -- ) shift ; break ;;
	    --* ) echo "start_container: Unrecognized argument \"$1\"." >&2 ;;
	    * ) break ;;
	esac
	shift
    done

    if [[ -z "$release" ]] ; then
	release=$(set $(get_dist_releases_$distribution) ; echo $1)
	if [[ -z "$release" ]] ; then
	    echo "start_container: Unable to determine default release for distribution \"${distro}\"." >&2
	    echo "Failing." >&2
	    return 1
	fi
    fi

    "start_container_$container_system" --distribution="$distribution" --release="$release" "$@"
}


# Trivial implementation for the "none" driver.  You can set the
# container command prefix to be something like "ssh -p some_port some_host"
# implement ssh into a host as a container.

container_command_prefix=
start_container_none() { in_container_none "$@" ; }
stop_container_none() { true ; }
in_container_none() { $container_command_prefix "$@" ; }

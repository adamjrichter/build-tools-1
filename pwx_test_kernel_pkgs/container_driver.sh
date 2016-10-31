# To be sourced by a shell script

container_system=docker	# force this default for now.
. $scriptsdir/container_driver.docker.sh
. $scriptsdir/container_driver.lxc.sh

start_container() { "start_container_$container_system" "$@" ; }
stop_container() { "stop_container_$container_system" "$@" ; }
in_container() { "in_container_$container_system" "$@" ; }

# Trivial implementation for the "none" driver.  You can set the
# container command prefix to be something like "ssh -p some_port some_host"
# implement ssh into a host as a container.

container_command_prefix=
start_container_none() { in_container_none "$@" ; }
stop_container_none() { true ; }
in_container_none() { $container_command_prefix "$@" ; }

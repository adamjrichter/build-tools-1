# To be sourced by a shell script

# Global variables:
docker_pid=

start_container_docker() {
    local container_name="pwx_test_${distribution}"
    local id

    systemctl start docker
    id=$(docker ps --quiet=true --all=true --filter name="${container_name}")
    if [ -n "$id" ] ; then
	docker start "$id"
	docker_pid="$id"
	return 0
    else
	docker pull $distribution
        docker_pid=$(docker run --interactive --name "${container_name}" --detach "$distribution" bash)
	"$@"
    fi
}

stop_container_docker() {
    docker stop "$container_pid"
    docker rm --volumes=true "$docker_pid"
}

in_container_docker() {
    docker exec --interactive "$docker_pid" "$@"
}

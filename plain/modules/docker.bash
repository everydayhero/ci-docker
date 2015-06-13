# Commands for working with docker

init() {
  env-import DOCKER_USERNAME
  env-import DOCKER_PASSWORD
  env-import DOCKER_EMAIL "."
  env-import DOCKER_SERVER "quay.io"

  cmd-export-ns docker "Build, Ship and Run Any App, Anywhere"
  cmd-export docker-login
  cmd-export docker-build
  cmd-export docker-push
}

# Build a docker container for a service
#
# example:
#   $ gun docker build payments $(git rev-parse HEAD) .
docker-build() {
  declare desc="Build a docker container for a service"
  declare service="$1" revision="$2" path="$3"
  service_image=$(config-service-image $service)
  command docker build -t "${service_image}:${revision}" "${path}"
}

# Push a tagged build to a docker server
#
# example:
#   $ gun docker push payments $(get rev-parse HEAD)
docker-push() {
  declare desc="Push a tagged build to a docker server"
  declare service="$1" revision="$2"
  service_image=$(config-service-image $service)
  docker-login && \
    command docker push "${service_image}:${revision}"
}

# Login to a docker server
#
# example:
#   $ gun docker login
docker-login() {
  declare desc="Login to a docker server"
  command docker login \
    --email="${DOCKER_EMAIL}" \
    --username="${DOCKER_USERNAME}" \
    --password="${DOCKER_PASSWORD}" \
    "${DOCKER_SERVER}"
}

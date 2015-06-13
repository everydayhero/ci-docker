# Service management

init() {
	cmd-export-ns service "Service management"
	cmd-export service-status-all
	cmd-export service-status
	cmd-export service-logs
	cmd-export service-stop
	cmd-export service-start
	cmd-export service-run
	cmd-export service-list
	cmd-export service-import
	cmd-export service-endpoints
	cmd-export service-create
	cmd-export service-destroy
	cmd-export service-build
}

service-status-all() {
	declare desc="Show unit status for all services"
	for service in $(service-list); do
		service-status "$service"
	done
}

service-status() {
	declare desc="Show unit status for service"
	declare service="$1" version="$2" instance="$3"
	if [[ ! "$version" ]]; then
		version="$(release-current $service)"
	fi
	local release
	release="$service-$version"
	_remote() {
		systemctl status "$release" -n 0 | head -n 3
	}
	if [[ "$instance" ]]; then
		ec2-ssh "$instance" "release=$release; $(fn-source _remote)"
	else
		ec2-pssh "$service" "release=$release; $(fn-source _remote)"
	fi
}

service-logs() {
	declare desc="Tail logs of service"
	declare service="$1" version="$2" instance="$3"
	if [[ ! "$version" ]]; then
		version="$(release-current $service)"
	fi
	local release
	release="$service-$version"
	_remote() {
		journalctl -u "$release" -f
	}
	if [[ "$instance" ]]; then
		ec2-ssh "$instance" "release=$release; $(fn-source _remote)"
	else
		ec2-pssh "$service" "release=$release; $(fn-source _remote)"
	fi
}

service-stop() {
	declare desc="Stop unit for service"
	declare service="$1" version="$2" instance="$3"
	if [[ ! "$version" ]]; then
		version="$(release-current $service)"
	fi
	local release
	release="$service-$version"
	_remote() {
		sudo systemctl stop "$release"
		systemctl status "$release" -n 0 | head -n 3 || true
	}
	if [[ "$instance" ]]; then
		ec2-ssh "$instance" "release=$release; $(fn-source _remote)"
	else
		ec2-pssh "$service" "release=$release; $(fn-source _remote)"
	fi
}

service-start() {
	declare desc="Start unit for service"
	declare service="$1" version="$2" instance="$3"
	if [[ ! "$version" ]]; then
		version="$(release-current $service)"
	fi
	local release
	release="$service-$version"
	_remote() {
		sudo systemctl start "$release"
		systemctl status "$release" -n 0 | head -n 3
	}
	if [[ "$instance" ]]; then
		ec2-ssh "$instance" "release=$release; $(fn-source _remote)"
	else
		ec2-pssh "$service" "release=$release; $(fn-source _remote)"
	fi
}

service-run() {
	declare desc="Run one-off command for service"
	declare service="$1" version="$2"; shift; shift
	if [[ ! "$version" ]]; then
		version="$(release-current $service)"
	fi
	local release instance
	release="$service-$version"
	instance="$(ec2-list "$service" | jq -e -r '.[0].name')"
	: "${instance:?}"
	ec2-ssh "$instance" "source /home/core/releases/$release; \
		docker run --rm \
			-e SERVICE_IGNORE=true \
			--env-file /home/core/releases/$release \
			\$SERVICE_IMAGE $@"
}

service-list() {
	declare desc="List configured services"
	declare service="$1"
	consul-ls "/${EC2_VPC:?}/config"
}

# Create a service
#
# Ideally creating a new service should:
#   * setup quay.io
#   * setup buildkite.com
#
# example:
#   $ gun service create payments quay.io/everydayhero/payments
service-create() {
  declare desc="Create a service"
  declare service="$1"
  declare image="$2"
  config-set "$service" "SERVICE_IMAGE" "$image"
}

# Destroy a service
#
# At the moment this only removes keys from consul, ideally also removes:
#   * unit files
#
# example:
#   $ gun service destroy payments
service-destroy() {
  declare desc="Destroy a service"
  declare service="$1"
  config-unset-all $1
  release-destroy-all $1
}

# Make a service container available for release
#
# Build a container and push to a docker server if required.
#
# example:
#   $ gun service build payments $(git rev-parse HEAD)
service-build() {
  declare desc="Make a service container available for release"
  declare service="$1" revision="$2" path="$3"
  # TODO: is there a way to query the registry and check if our build has been
  #       previously pushed? In the event of a configuration change we can skip
  #       docker build and just cut a new release.
  docker-build "${service}" "${revision}" "${path}" && \
    docker-push "${service}" "${revision}"
}

service-import() {
	declare desc="Import service from fig.yml"
	declare filename="$1" service="$2" as="$3"
	: "${filename:?}" "${service:?}" "${as:?}"
	config-set "$as" "SERVICE_IMAGE" "$(fig-image $filename $service)"
	fig-environment "$filename" "$service" \
		| consul-import "${EC2_VPC:?}/config/$as" \
		|| true
	config-get "$as"
}

service-endpoints() {
	declare desc="List healthy endpoints for a service"
	declare service="$1"
	release="$service-$(release-current $service)"
	consul-service "$release" | jq -e -r '.[] | "\(.Node.Address):\(.Service.Port)"'
}

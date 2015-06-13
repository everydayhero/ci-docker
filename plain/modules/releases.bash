# Release management commands

init() {
	cmd-export-ns release "Release management"
	cmd-export release-create
	cmd-export release-show
	cmd-export release-latest
	cmd-export release-current
	cmd-export release-get
	cmd-export release-destroy-all
}

# Create a new release
#
# A release is defined as:
#   * code revision
#   * configuration
#   * build number
#
# example:
#   $ release create payments $(git rev-parse HEAD) 123
release-create() {
  declare desc="Create a new release"
  declare service="$1" revision="$2" build="${3}"
  if ! release-latest "$service" > /dev/null 2>&1; then
    consul-set "${EC2_VPC:?}/releases/${service:?}/latest" "v0"
  fi
  local snapshot latest
  snapshot="$(consul-export "${EC2_VPC:?}/config/${service:?}" || true)"
  snapshot+=$(printf "\nPLAIN_REVISION=%s" "${revision}")
  snapshot+=$(printf "\nPLAIN_CI_BUILD_NUMBER=%s" "${build}")
  latest="$(release-latest $service)"
  latest="v$((${latest/v/}+1))"
  # TODO: commit atomically - https://github.com/hashicorp/consul/issues/886
  consul-set "${EC2_VPC:?}/releases/${service:?}/$latest" "$snapshot"
  consul-set "${EC2_VPC:?}/releases/${service:?}/latest" "$latest"

  echo "$latest"
}

release-get() {
	declare desc="Get contents of existing release"
	declare service="$1" version="$2"
	consul-get "${EC2_VPC:?}/releases/${service:?}/v${version/v/}"
}

release-current() {
	declare desc="Get or set current release version"
	declare service="$1" version="$2"
	if [[ "$version" ]]; then
		release-get "$service" "$version" > /dev/null
		consul-set "${EC2_VPC:?}/releases/${service:?}/current" "v${version/v/}"
	fi
	consul-get "${EC2_VPC:?}/releases/${service:?}/current"
}

release-latest() {
	declare desc="Get latest release version"
	declare service="$1"
	consul-get "${EC2_VPC:?}/releases/${service:?}/latest"
}

release-show() {
	declare desc="Show releases information"
	declare service="$1"
	echo "Latest:  $(release-latest $service)"
	echo "Current: $(release-current $service)"
	consul-ls "${EC2_VPC:?}/releases/${service:?}" \
		| grep -v latest \
		| grep -v current
}

# Destroy all releases for a service
#
# example:
#   $ gun release destroy all payments
release-destroy-all() {
  declare desc="Destroy all releases for a service"
  declare service="$1"
  consul-del "${EC2_VPC:?}/releases/${service:?}?recurse"
}

# Deployment commands

init() {
  cmd-export-ns deploy "Deployment commands"
  cmd-export deploy-release
  cmd-export deploy-rollout
  cmd-export deploy-rollback
  cmd-export deploy-clean
}

# Deploy a new release
#
# Create then deploy a new new release.
#
# example:
#   $ gun deploy rollout payments $(git rev-parse HEAD) 123
deploy-rollout() {
  declare desc="Rollout a new release"
  declare service="$1" revision="$2" build="${3}"
  deploy-release "$service" "$(release-create $service $revision $build)"
}

# Rollback to a previous release
#
# Deploy a previous release.
#
# example: rollback to the previous release
#   $ gun deploy rollback payments
#
# example: rollback to a specified release
#   $ gun deploy rollback payments v2
deploy-rollback() {
  declare desc="Rollback to previous release"
  declare service="$1" version="$2"
  if [[ ! "$version" ]]; then
    version="$(release-current $service)"
    version="v$((${version/v/}-1))"
  fi
  deploy-release "$service" "$version"
}

# Deploy a release
#
# Deploying a new release is as easy as:
#   1. Copy the release's config to all nodes that require it
#   2. Restart service
#
# example:
#   $ gun deploy release payments v23
deploy-release() {
  declare desc="Deploy a release"
  declare service="$1" version="$2"
  : "${service:?}" "${version:?}"
  local release
  version="v${version/v/}"
  release="${service}-${version}"
  release-get "$service" "$version" > "$PWD/.${release}"
  ec2-prsync "$service" "$PWD/.${release}" "/srv/plain/releases/${release}"

  _remote() {
    units_dir="/srv/plain/units"

    # Create a unit file for formations. The following is an example formation
    # for the payments service:
    #   /srv/plain/formations/payments-web-0
    #   /srv/plain/formations/payments-web-1
    #   /srv/plain/formations/payments-web-2
    #   /srv/plain/formations/payments-worker-0
    #   /srv/plain/formations/payments-clock-0
    for formation in /srv/plain/formations/$service-*; do
      formation_filename=$(basename $formation)
      process=$(echo "${formation_filename}" | sed "s/${service}-//" | rev | cut -d\- -f2- | rev)

      index=$(echo "${formation_filename}" | rev | cut -d\- -f1)
      unit_file_filename="${service}-${version}-${process}-${index}.service"
      unit_file="${units_dir}/${unit_file_filename}"

      cat "${units_dir}/service.unit" \
        | sed "s/SERVICE/${service}/g" \
        | sed "s/RELEASE/${version}/g" \
        | sed "s/PROCESS/${process}/g" \
        | sed "s:ENVIRONMENT_FILE:${formation}:g" \
        > "${unit_file}"

      sudo systemctl -q link "${unit_file}"
      sudo systemctl -q start "${unit_file_filename}" || true
      systemctl status "${unit_file_filename}" -n 0 | head -n 3
    done
  }

  ec2-pssh "${service}" "service=${service}; version=${version}; $(fn-source _remote)"
  release-current "${service}" "${version}"
}

# Cleanup old releases
#
# After a deployment occurs you will be running two releases simultaneously, the
# previous releases needs to be stopped and removed.
#
# example:
#   $ gun deploy clean payments
deploy-clean() {
 declare desc="Stop old releases"
 declare service="$1"
 : "${service:?}"
 local release="$service-$(release-current $service)"
 _remote() {
   for path in /srv/plain/releases/$service-*; do
     oldrelease="$(basename $path)"
     if [[ "$oldrelease" != "$release" ]]; then
       echo "$oldrelease"
       sudo systemctl -q stop "$oldrelease*"
     fi
   done
 }
 ec2-pssh "$service" "service=$service; release=$release; $(fn-source _remote)"
}

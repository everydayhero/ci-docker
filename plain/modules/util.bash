# Misc utility functions / commands

cloud-config() {
	declare desc="Generates cloud-config"
	declare filename="$1" hostname="$2"; shift; shift
	local script k v
	for var in "$@"; do
		IFS='=' read k v <<< "$var"
		script="s/\$\$$k/${var##${k}=}/;$script"
	done
	cat "$PWD/config/$filename" | sed "$script"
	cat "$PWD/config/_keys.yaml"
	echo "hostname: $hostname"
}

random-string() {
	declare desc="Generates a random string of characters"
	declare size="${1:-64}"
	cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w "$size" | head -n 1 || true
}

port-wait() {
	declare desc="Waits until a port is open"
	declare host="$1" port="$2" attempts="${3:-30}"
	for retry in $(seq 1 $attempts); do
		sleep 1 && nc -z -w 5 "$host" "$port" > /dev/null && return
	done
	echo "!! Unable to reach $host:$port after $attempts tries."
	exit 2
}

info() {
	[[ "${FUNCNAME[2]}" == "cmd-ns" ]] || return 0
	echo "===>" $@ >&2
}


titleize() {
	for word in "$@"; do
		printf '%s ' "${word^}"
	done
	echo
}

parallel() {
	declare cmd="$@"
	declare -a pids
	for line in $(cat); do
		eval "${cmd//\{\}/$line} &"
		pids+=($!)
	done
	local failed=$((0))
	for pid in ${pids[@]}; do
		if ! wait $pid; then
			failed=$((failed + 1))
		fi
	done
	return $((failed))
}

ssh-cmd() {
	echo "ssh -A $SSH_OPTS $@"
}

coreos-ami() {
	declare region="$1"
	curl -s "http://stable.release.core-os.net/amd64-usr/current/coreos_production_ami_hvm_${region}.txt"
}

parse-yaml() {
	declare prefix="$1"
	local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
	sed -ne "s|^\($s\):|\1|" \
	    -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
	    -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" \
	    | awk -F$fs '{
			indent = length($1)/2;
			vname[indent] = $2;
			for (i in vname) {if (i > indent) {delete vname[i]}}
			if (length($3) > 0) {
				vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
				printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
			}
		}'
}

fig-project() {
	declare filename="$1"
	basename "$(dirname $filename)"
}

fig-services() {
	declare filename="$1"
	cat "$filename" \
		| parse-yaml \
		| cut -d'_' -f1 \
		| uniq
}

fig-image() {
	declare filename="$1" service="$2"
	local image_kvp image_key
	image_key="${service}_image"
	image_kvp="$(cat $filename | parse-yaml | grep -e "${image_key}=" || true)"
	if [[ "$image_kvp" ]]; then
		eval "$image_kvp"
		echo "${!image_key}"
	else
		echo "$(fig-project $filename)_$service"
	fi
}

fig-environment() {
	declare filename="$1" service="$2"
	cat "$filename" \
		| parse-yaml \
		| grep -e "${service}_environment_" \
		| sed "s/${service}_environment_//"
}

#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${MAGEFLEET_ENV_PATH}" || exit $?

## set defaults for this command which can be overridden either using exports in the user
## profile or setting them in the .env configuration on a per-project basis
MAGEFLEET_ENV_DEBUG_COMMAND=${MAGEFLEET_ENV_DEBUG_COMMAND:-bash}
MAGEFLEET_ENV_DEBUG_CONTAINER=${MAGEFLEET_ENV_DEBUG_CONTAINER:-php-debug}
MAGEFLEET_ENV_DEBUG_HOST=${MAGEFLEET_ENV_DEBUG_HOST:-}

if [[ ${MAGEFLEET_ENV_DEBUG_HOST} == "" ]]; then
    if [[ $OSTYPE =~ ^darwin ]] || grep -sqi microsoft /proc/sys/kernel/osrelease; then
        MAGEFLEET_ENV_DEBUG_HOST=host.docker.internal
    else
        MAGEFLEET_ENV_DEBUG_HOST=$(
            docker container inspect $($MAGEFLEET_BIN env ps -q php-debug) \
                --format '{{range .NetworkSettings.Networks}}{{println .Gateway}}{{end}}' | head -n1
        )
    fi
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

"$MAGEFLEET_BIN" env exec -e "XDEBUG_REMOTE_HOST=${MAGEFLEET_ENV_DEBUG_HOST}" \
    "${MAGEFLEET_ENV_DEBUG_CONTAINER}" "${MAGEFLEET_ENV_DEBUG_COMMAND}" "${MAGEFLEET_PARAMS[@]}" "$@"

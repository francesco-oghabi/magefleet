#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${MAGEFLEET_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${MAGEFLEET_REDIS:-1} -eq 0 ]]; then
  fatal "Redis environment is not used (MAGEFLEET_REDIS=0)."
fi

if [[ "${MAGEFLEET_PARAMS[0]}" == "help" ]]; then
  $MAGEFLEET_BIN redis --help || exit $? && exit $?
fi

## load connection information for the redis service
REDIS_CONTAINER=$($MAGEFLEET_BIN env ps -q redis)
if [[ ! ${REDIS_CONTAINER} ]]; then
    fatal "No container found for redis service."
fi

"$MAGEFLEET_BIN" env exec redis redis-cli "${MAGEFLEET_PARAMS[@]}" "$@"

#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${MAGEFLEET_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${MAGEFLEET_VALKEY:-1} -eq 0 ]]; then
  fatal "Valkey environment is not used (MAGEFLEET_VALKEY=0)."
fi

if [[ "${MAGEFLEET_PARAMS[0]}" == "help" ]]; then
  $MAGEFLEET_BIN valkey --help || exit $? && exit $?
fi

## load connection information for the Valkey service
VALKEY_CONTAINER=$($MAGEFLEET_BIN env ps -q valkey)
if [[ ! ${VALKEY_CONTAINER} ]]; then
    fatal "No container found for Valkey service."
fi

"$MAGEFLEET_BIN" env exec valkey valkey-cli "${MAGEFLEET_PARAMS[@]}" "$@"

#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${MAGEFLEET_ENV_PATH}" || exit $?

## set defaults for this command which can be overridden either using exports in the user
## profile or setting them in the .env configuration on a per-project basis
MAGEFLEET_ENV_SPX_COMMAND=${MAGEFLEET_ENV_SPX_COMMAND:-bash}
MAGEFLEET_ENV_SPX_CONTAINER=${MAGEFLEET_ENV_SPX_CONTAINER:-php-spx}

## allow return codes from sub-process to bubble up normally
trap '' ERR

"$MAGEFLEET_BIN" env exec "${MAGEFLEET_ENV_SPX_CONTAINER}" \
    "${MAGEFLEET_ENV_SPX_COMMAND}" "${MAGEFLEET_PARAMS[@]}" "$@"

#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## load usage info for the given command falling back on default usage text
if [[ -f "${MAGEFLEET_CMD_HELP}" ]]; then
  source "${MAGEFLEET_CMD_HELP}"
else
  source "${MAGEFLEET_DIR}/commands/usage.help"

  MAGEFLEET_ENV_PATH="$(locateEnvPath)" || true
  if [[ -n "${MAGEFLEET_ENV_PATH}" && -d "${MAGEFLEET_ENV_PATH}/.magefleet/commands" ]]; then
    CUSTOM_COMMAND_LIST=$(ls "${MAGEFLEET_ENV_PATH}/.magefleet/commands/"*.cmd)
    
    if [[ -n "${CUSTOM_COMMAND_LIST}" ]]; then
      TRIM_PREFIX="${MAGEFLEET_ENV_PATH}/.magefleet/commands/"
      TRIM_SUFFIX=".cmd"
      CUSTOM_COMMANDS=""
      for COMMAND in $CUSTOM_COMMAND_LIST; do
        COMMAND=${COMMAND#"$TRIM_PREFIX"}
        COMMAND=${COMMAND%"$TRIM_SUFFIX"}
        [[ ! -e "${TRIM_PREFIX}${COMMAND}.help" ]] && continue;
        CUSTOM_COMMANDS="${CUSTOM_COMMANDS}  ${COMMAND}"$'\n'
      done

      if [[ -n "${CUSTOM_COMMANDS}" ]]; then
        CUSTOM_ENV_COMMANDS=$'\n\n'"\033[33mCustom Commands For Environment \033[35m${MAGEFLEET_ENV_PATH##*/}\033[33m:\033[0m"
        CUSTOM_ENV_COMMANDS="$CUSTOM_ENV_COMMANDS"$'\n'"$CUSTOM_COMMANDS"
        MAGEFLEET_USAGE=$(cat <<EOF
${MAGEFLEET_USAGE}${CUSTOM_ENV_COMMANDS}
EOF
)
      fi
    fi
  fi
fi

echo -e "${MAGEFLEET_USAGE}"
exit 1

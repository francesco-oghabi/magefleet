#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(pwd -P)"

# Prompt user if there is an extant .env file to ensure they intend to overwrite
if test -f "${MAGEFLEET_ENV_PATH}/.env"; then
  while true; do
    read -p $'\033[32mA warden env file already exists at '"${MAGEFLEET_ENV_PATH}/.env"$'; would you like to overwrite? y/n\033[0m ' resp
    case $resp in
      [Yy]*) echo "Overwriting extant .env file"; break;;
      [Nn]*) exit;;
      *) echo "Please answer (y)es or (n)o";;
    esac
  done
fi

MAGEFLEET_ENV_NAME="${MAGEFLEET_PARAMS[0]:-}"

# If warden environment name was not provided, prompt user for it
while [ -z "${MAGEFLEET_ENV_NAME}" ]; do
  read -p $'\033[32mAn environment name was not provided; please enter one:\033[0m ' MAGEFLEET_ENV_NAME
done

MAGEFLEET_ENV_TYPE="${MAGEFLEET_PARAMS[1]:-}"

# If warden environment type was not provided, prompt user for it
if [ -z "${MAGEFLEET_ENV_TYPE}" ]; then
  while true; do
    read -p $'\033[32mAn environment type was not provided; please choose one of ['"$(fetchValidEnvTypes)"$']:\033[0m ' MAGEFLEET_ENV_TYPE
    assertValidEnvType && break
  done
fi

# Verify the auto-select and/or type path resolves correctly before setting it
assertValidEnvType || exit $?

# Write the .env file to current working directory
cat > "${MAGEFLEET_ENV_PATH}/.env" <<EOF
MAGEFLEET_ENV_NAME=${MAGEFLEET_ENV_NAME}
MAGEFLEET_ENV_TYPE=${MAGEFLEET_ENV_TYPE}
MAGEFLEET_WEB_ROOT=/

TRAEFIK_DOMAIN=${MAGEFLEET_ENV_NAME}.test
TRAEFIK_SUBDOMAIN=app
EOF

ENV_INIT_FILE=$(fetchEnvInitFile)
if [[ ! -z $ENV_INIT_FILE ]]; then
  export MAGEFLEET_ENV_NAME
  export GENERATED_APP_KEY="base64:$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64)"
  envsubst '$MAGEFLEET_ENV_NAME:$GENERATED_APP_KEY' < "${ENV_INIT_FILE}" >> "${MAGEFLEET_ENV_PATH}/.env"
fi

if [ -s "${MAGEFLEET_ENV_PATH}/.env" ]; then
  printf "A warden env file was created at ${MAGEFLEET_ENV_PATH}/.env\nYou may now use \'magefleet env up\' to start your environment.\n"
  exit 0
fi
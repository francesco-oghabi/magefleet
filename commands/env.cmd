#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${MAGEFLEET_ENV_PATH}" || exit $?
assertDockerRunning

## warn if global services are not running
if [[ "${MAGEFLEET_PARAMS[0]}" == "up" ]]; then
    assertSvcRunning
fi

HOST_UID=$(id -u)
HOST_GID=$(id -g)

if (( ${#MAGEFLEET_PARAMS[@]} == 0 )) || [[ "${MAGEFLEET_PARAMS[0]}" == "help" ]]; then
  # shellcheck disable=SC2153
  $MAGEFLEET_BIN env --help || exit $? && exit $?
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

## define source repository
if [[ -f "${MAGEFLEET_HOME_DIR}/.env" ]]; then
  eval "$(sed 's/\r$//g' < "${MAGEFLEET_HOME_DIR}/.env" | grep "^MAGEFLEET_")"
fi
export MAGEFLEET_IMAGE_REPOSITORY="${MAGEFLEET_IMAGE_REPOSITORY:-"docker.io/magefleetenv"}"

## configure environment type defaults
if [[ ${MAGEFLEET_ENV_TYPE} =~ ^magento ]]; then
    export MAGEFLEET_SVC_PHP_VARIANT=-${MAGEFLEET_ENV_TYPE}
fi
if [[ ${MAGEFLEET_NIGHTLY} -eq 1 ]]; then
    export MAGEFLEET_SVC_PHP_IMAGE_SUFFIX="-indev"
fi

## configure xdebug version
export XDEBUG_VERSION="debug" # xdebug2 image
if [[ ${PHP_XDEBUG_3} -eq 1 ]]; then
    export XDEBUG_VERSION="xdebug3"
fi

if [[ ${MAGEFLEET_ENV_TYPE} != local ]]; then
    MAGEFLEET_NGINX=${MAGEFLEET_NGINX:-1}
    MAGEFLEET_DB=${MAGEFLEET_DB:-1}
    MAGEFLEET_REDIS=${MAGEFLEET_REDIS:-1}

    # define bash history folder for changing permissions
    MAGEFLEET_CHOWN_DIR_LIST="/bash_history /home/www-data/.ssh ${MAGEFLEET_CHOWN_DIR_LIST:-}"
fi
export CHOWN_DIR_LIST=${MAGEFLEET_CHOWN_DIR_LIST:-}

if [[ ${MAGEFLEET_ENV_TYPE} == "magento1" && -f "${MAGEFLEET_ENV_PATH}/.modman/.basedir" ]]; then
  NGINX_PUBLIC='/'$(cat "${MAGEFLEET_ENV_PATH}/.modman/.basedir")
  export NGINX_PUBLIC
fi

if [[ ${MAGEFLEET_ENV_TYPE} == "magento2" ]]; then
    MAGEFLEET_VARNISH=${MAGEFLEET_VARNISH:-1}
    MAGEFLEET_ELASTICSEARCH=${MAGEFLEET_ELASTICSEARCH:-1}
    MAGEFLEET_RABBITMQ=${MAGEFLEET_RABBITMQ:-1}
    MAGEFLEET_MAGENTO2_GRAPHQL_SERVER=${MAGEFLEET_MAGENTO2_GRAPHQL_SERVER:-0}
    MAGEFLEET_MAGENTO2_GRAPHQL_SERVER_DEBUG=${MAGEFLEET_MAGENTO2_GRAPHQL_SERVER_DEBUG:-0}
fi

## WSL1/WSL2 are GNU/Linux env type but still run Docker Desktop
if [[ ${XDEBUG_CONNECT_BACK_HOST} == '' ]] && grep -sqi microsoft /proc/sys/kernel/osrelease; then
    export XDEBUG_CONNECT_BACK_HOST=host.docker.internal
fi

## For linux, if UID is 1000, there is no need to use the socat proxy.
if [[ ${MAGEFLEET_ENV_SUBT} == "linux" && $UID == 1000 ]]; then
    export SSH_AUTH_SOCK_PATH_ENV=/run/host-services/ssh-auth.sock
fi

## configure docker compose files
DOCKER_COMPOSE_ARGS=()

appendEnvPartialIfExists "networks"

if [[ ${MAGEFLEET_ENV_TYPE} != local ]]; then
    appendEnvPartialIfExists "php-fpm"
fi

[[ ${MAGEFLEET_NGINX} -eq 1 ]] \
    && appendEnvPartialIfExists "nginx"

[[ ${MAGEFLEET_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "db"

[[ ${MAGEFLEET_ELASTICSEARCH} -eq 1 ]] \
    && appendEnvPartialIfExists "elasticsearch"

[[ ${MAGEFLEET_ELASTICHQ:=1} -eq 1 ]] \
    && appendEnvPartialIfExists "elastichq"

[[ ${MAGEFLEET_OPENSEARCH} -eq 1 ]] \
    && appendEnvPartialIfExists "opensearch"

[[ ${MAGEFLEET_VARNISH} -eq 1 ]] \
    && appendEnvPartialIfExists "varnish"

[[ ${MAGEFLEET_RABBITMQ} -eq 1 ]] \
    && appendEnvPartialIfExists "rabbitmq"

[[ ${MAGEFLEET_REDIS} -eq 1 ]] \
    && appendEnvPartialIfExists "redis"

[[ ${MAGEFLEET_VALKEY:=0} -eq 1 ]] \
    && appendEnvPartialIfExists "valkey"

appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}"

[[ ${MAGEFLEET_TEST_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}.tests"

[[ ${MAGEFLEET_SPLIT_SALES} -eq 1 ]] \
    && appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}.splitdb.sales"

[[ ${MAGEFLEET_SPLIT_CHECKOUT} -eq 1 ]] \
    && appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}.splitdb.checkout"

if [[ ${MAGEFLEET_BLACKFIRE} -eq 1 ]]; then
    appendEnvPartialIfExists "blackfire"
    appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}.blackfire"
fi

[[ ${MAGEFLEET_ALLURE} -eq 1 ]] \
    && appendEnvPartialIfExists "allure"

[[ ${MAGEFLEET_SELENIUM} -eq 1 ]] \
    && appendEnvPartialIfExists "selenium"

[[ ${MAGEFLEET_MAGEPACK} -eq 1 ]] \
    && appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}.magepack"

[[ ${MAGEFLEET_MAGENTO2_GRAPHQL_SERVER} -eq 1 ]] \
    && appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}.graphql"
[[ ${MAGEFLEET_MAGENTO2_GRAPHQL_SERVER_DEBUG} -eq 1 ]] \
    && appendEnvPartialIfExists "${MAGEFLEET_ENV_TYPE}.graphql-debug"

[[ ${MAGEFLEET_PHP_SPX} -eq 1 ]] \
    && appendEnvPartialIfExists "php-spx"

if [[ -f "${MAGEFLEET_ENV_PATH}/.magefleet/magefleet-env.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_ENV_PATH}/.magefleet/magefleet-env.yml")
fi

if [[ -f "${MAGEFLEET_ENV_PATH}/.magefleet/magefleet-env.${MAGEFLEET_ENV_SUBT}.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_ENV_PATH}/.magefleet/magefleet-env.${MAGEFLEET_ENV_SUBT}.yml")
fi

if [[ ${MAGEFLEET_SELENIUM_DEBUG} -eq 1 ]]; then
    export MAGEFLEET_SELENIUM_DEBUG="-debug"
else
    export MAGEFLEET_SELENIUM_DEBUG=
fi

## disconnect peered service containers from environment network
if [[ "${MAGEFLEET_PARAMS[0]}" == "down" ]]; then
    disconnectPeeredServices "$(renderEnvNetworkName)"

    ## regenerate PMA config on each env changing
    regeneratePMAConfig
fi

## connect peered service containers to environment network
if [[ "${MAGEFLEET_PARAMS[0]}" == "up" ]]; then
    ## create environment network for attachments if it does not already exist
    if [[ $(docker network ls -f "name=$(renderEnvNetworkName)" -q) == "" ]]; then
        ${DOCKER_COMPOSE_COMMAND} \
            --project-directory "${MAGEFLEET_ENV_PATH}" -p "${MAGEFLEET_ENV_NAME}" \
            "${DOCKER_COMPOSE_ARGS[@]}" up --no-start
    fi

    ## connect globally peered services to the environment network
    connectPeeredServices "$(renderEnvNetworkName)"

    ## always execute env up using --detach mode
    if ! (containsElement "-d" "$@" || containsElement "--detach" "$@"); then
        MAGEFLEET_PARAMS=("${MAGEFLEET_PARAMS[@]:1}")
        MAGEFLEET_PARAMS=(up -d "${MAGEFLEET_PARAMS[@]}")
    fi

    ## regenerate PMA config on each env changing
    regeneratePMAConfig
fi

## lookup address of traefik container on environment network
TRAEFIK_ADDRESS="$(docker container inspect traefik \
    --format '
        {{- $network := index .NetworkSettings.Networks "'"$(renderEnvNetworkName)"'" -}}
        {{- if $network }}{{ $network.IPAddress }}{{ end -}}
    ' 2>/dev/null || true
)"
export TRAEFIK_ADDRESS;

if [[ ${MAGEFLEET_MUTAGEN_ENABLE} -eq 1 ]]; then
    export MUTAGEN_SYNC_FILE="${MAGEFLEET_DIR}/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.mutagen.yml"

    if [[ -f "${MAGEFLEET_HOME_DIR}/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.mutagen.yml" ]]; then
        export MUTAGEN_SYNC_FILE="${MAGEFLEET_HOME_DIR}/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.mutagen.yml"
    fi

    if [[ -f "${MAGEFLEET_ENV_PATH}/.magefleet/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.mutagen.yml" ]]; then
        export MUTAGEN_SYNC_FILE="${MAGEFLEET_ENV_PATH}/.magefleet/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.mutagen.yml"
    fi

    if [[ -f "${MAGEFLEET_ENV_PATH}/.magefleet/mutagen.yml" ]]; then
        export MUTAGEN_SYNC_FILE="${MAGEFLEET_ENV_PATH}/.magefleet/mutagen.yml"
    fi
fi

## pause mutagen sync if needed
if [[ "${MAGEFLEET_PARAMS[0]}" == "stop" ]] \
    && [[ ${MAGEFLEET_MUTAGEN_ENABLE} -eq 1 ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]]
then
    $MAGEFLEET_BIN sync pause
fi

## pass orchestration through to docker compose
${DOCKER_COMPOSE_COMMAND} \
    --project-directory "${MAGEFLEET_ENV_PATH}" -p "${MAGEFLEET_ENV_NAME}" \
    "${DOCKER_COMPOSE_ARGS[@]}" "${MAGEFLEET_PARAMS[@]}" "$@"


if [[ "${MAGEFLEET_PARAMS[0]}" == "stop" || "${MAGEFLEET_PARAMS[0]}" == "down" || \
      "${MAGEFLEET_PARAMS[0]}" == "up" || "${MAGEFLEET_PARAMS[0]}" == "start" ]]; then
    regeneratePMAConfig
fi

## resume mutagen sync if available and php-fpm container id hasn't changed
if { [[ "${MAGEFLEET_PARAMS[0]}" == "up" ]] || [[ "${MAGEFLEET_PARAMS[0]}" == "start" ]]; } \
    && [[ ${MAGEFLEET_MUTAGEN_ENABLE} -eq 1 ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]] \
    && [[ $($MAGEFLEET_BIN sync list | grep -ci 'Status: \[Paused\]' | awk '{print $1}') == "1" ]] \
    && [[ $($MAGEFLEET_BIN env ps -q php-fpm) ]] \
    && [[ $(docker container inspect "$($MAGEFLEET_BIN env ps -q php-fpm)" --format '{{ .State.Status }}') = "running" ]] \
    && [[ $($MAGEFLEET_BIN env ps -q php-fpm) = $($MAGEFLEET_BIN sync list | grep -i 'URL: docker' | awk -F'/' '{print $3}') ]]
then
    $MAGEFLEET_BIN sync resume
fi

if [[ ${MAGEFLEET_MUTAGEN_ENABLE} -eq 1 ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]] # If we're using Mutagen
then
  MUTAGEN_VERSION=$(mutagen version)
  CONNECTION_STATE_STRING='Connected state: Connected'
  if [[ $((10#$(version "${MUTAGEN_VERSION}"))) -ge $((10#$(version '0.15.0'))) ]]; then
    CONNECTION_STATE_STRING='Connected: Yes'
  fi

  ## start mutagen sync if needed
  if { [[ "${MAGEFLEET_PARAMS[0]}" == "up" ]] || [[ "${MAGEFLEET_PARAMS[0]}" == "start" ]]; } \
      && [[ $($MAGEFLEET_BIN sync list | grep -c "${CONNECTION_STATE_STRING}" | awk '{print $1}') != "2" ]] \
      && [[ $($MAGEFLEET_BIN env ps -q php-fpm) ]] \
      && [[ $(docker container inspect "$($MAGEFLEET_BIN env ps -q php-fpm)" --format '{{ .State.Status }}') = "running" ]]
  then
      $MAGEFLEET_BIN sync start
  fi
fi

## stop mutagen sync if needed
if [[ "${MAGEFLEET_PARAMS[0]}" == "down" ]] \
    && [[ ${MAGEFLEET_MUTAGEN_ENABLE} -eq 1 ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]]
then
    $MAGEFLEET_BIN sync stop
fi

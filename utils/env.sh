#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function locateEnvPath () {
    local MAGEFLEET_ENV_PATH="$(pwd -P)"
    while [[ "${MAGEFLEET_ENV_PATH}" != "/" ]]; do
        if [[ -f "${MAGEFLEET_ENV_PATH}/.env" ]] \
            && grep "^MAGEFLEET_ENV_NAME" "${MAGEFLEET_ENV_PATH}/.env" >/dev/null \
            && grep "^MAGEFLEET_ENV_TYPE" "${MAGEFLEET_ENV_PATH}/.env" >/dev/null
        then
            break
        fi
        MAGEFLEET_ENV_PATH="$(dirname "${MAGEFLEET_ENV_PATH}")"
    done

    if [[ "${MAGEFLEET_ENV_PATH}" = "/" ]]; then
        >&2 echo -e "\033[31mEnvironment config could not be found. Please run \"magefleet env-init\" and try again!\033[0m"
        return 1
    fi

    ## Resolve .env symlink should it exist in project sub-directory allowing sub-stacks to use relative link to parent
    MAGEFLEET_ENV_PATH="$(
        cd "$(
            dirname "$(
                (readlink "${MAGEFLEET_ENV_PATH}/.env" || echo "${MAGEFLEET_ENV_PATH}/.env")
            )"
        )" >/dev/null \
        && pwd
    )"

    echo "${MAGEFLEET_ENV_PATH}"
}

function loadEnvConfig () {
    local MAGEFLEET_ENV_PATH="${1}"
    eval "$(cat "${MAGEFLEET_ENV_PATH}/.env" | sed 's/\r$//g' | grep "^MAGEFLEET_")"
    eval "$(cat "${MAGEFLEET_ENV_PATH}/.env" | sed 's/\r$//g' | grep "^TRAEFIK_")"
    eval "$(cat "${MAGEFLEET_ENV_PATH}/.env" | sed 's/\r$//g' | grep "^PHP_")"

    MAGEFLEET_ENV_NAME="${MAGEFLEET_ENV_NAME:-}"
    MAGEFLEET_ENV_TYPE="${MAGEFLEET_ENV_TYPE:-}"
    MAGEFLEET_ENV_SUBT=""

    case "${OSTYPE:-undefined}" in
        darwin*)
            MAGEFLEET_ENV_SUBT=darwin
        ;;
        linux*)
            MAGEFLEET_ENV_SUBT=linux
        ;;
        *)
            fatal "Unsupported OSTYPE '${OSTYPE:-undefined}'"
        ;;
    esac

    # Load mutagen settings if available
    if [[ -f "${MAGEFLEET_HOME_DIR}/.env" ]]; then
      eval "$(sed 's/\r$//g' < "${MAGEFLEET_HOME_DIR}/.env" | grep "^MAGEFLEET_MUTAGEN_ENABLE")"
    fi

    ## configure mutagen enable by default for MacOs
    if [[ $OSTYPE =~ ^darwin ]]; then
      export MAGEFLEET_MUTAGEN_ENABLE=${MAGEFLEET_MUTAGEN_ENABLE:-1}
    else
      # Disable mutagen for non-MacOS systems
      export MAGEFLEET_MUTAGEN_ENABLE=0
    fi

    assertValidEnvType
}

function renderEnvNetworkName() {
    echo "${MAGEFLEET_ENV_NAME}_default" | tr '[:upper:]' '[:lower:]'
}

function fetchEnvInitFile () {
    local envInitPath=""

    for ENV_INIT_PATH in \
        "${MAGEFLEET_DIR}/environments/${MAGEFLEET_ENV_TYPE}/init.env" \
        "${MAGEFLEET_HOME_DIR}/environments/${MAGEFLEET_ENV_TYPE}/init.env" \
        "${MAGEFLEET_ENV_PATH}/.magefleet/environments/${MAGEFLEET_ENV_TYPE}/init.env"
    do
        if [[ -f "${ENV_INIT_PATH}" ]]; then
            envInitPath="${ENV_INIT_PATH}"
        fi
    done

    echo $envInitPath
}

function fetchValidEnvTypes () {
    local lsPaths="${MAGEFLEET_DIR}/environments/"*/*".base.yml"

    if [[ -d "${MAGEFLEET_HOME_DIR}/environments" ]]; then
       lsPaths="${lsPaths} ${MAGEFLEET_HOME_DIR}/environments/"*/*".base.yml"
    fi

    if [[ -d "${MAGEFLEET_ENV_PATH}/.magefleet/environments" ]]; then
       lsPaths="${lsPaths} ${MAGEFLEET_ENV_PATH}/.magefleet/environments/"*/*".base.yml"
    fi

    echo $(
        ls -1 $lsPaths \
            | sed -E "s#^${MAGEFLEET_DIR}/environments/##" \
            | sed -E "s#^${MAGEFLEET_HOME_DIR}/environments/##" \
            | sed -E "s#^${MAGEFLEET_ENV_PATH}/.magefleet/environments/##" \
            | cut -d/ -f1 | sort | uniq | grep -v includes
    )
}

function assertValidEnvType () {
    if [[ -f "${MAGEFLEET_DIR}/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.base.yml" ]]; then
        return 0
    fi

    if [[ -f "${MAGEFLEET_HOME_DIR}/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.base.yml" ]]; then
        return 0
    fi

    if [[ -f "${MAGEFLEET_ENV_PATH}/.magefleet/environments/${MAGEFLEET_ENV_TYPE}/${MAGEFLEET_ENV_TYPE}.base.yml" ]]; then
        return 0
    fi

    >&2 echo -e "\033[31mInvalid environment type \"${MAGEFLEET_ENV_TYPE}\" specified.\033[0m"

    return 1
}

function appendEnvPartialIfExists () {
    local PARTIAL_NAME="${1}"
    local PARTIAL_PATH=""

    local BASE_PATHS=(
        "${MAGEFLEET_DIR}/environments/includes"
        "${MAGEFLEET_DIR}/environments/${MAGEFLEET_ENV_TYPE}"
        "${MAGEFLEET_HOME_DIR}/environments/includes"
        "${MAGEFLEET_HOME_DIR}/environments/${MAGEFLEET_ENV_TYPE}"
        "${MAGEFLEET_ENV_PATH}/.magefleet/environments/includes"
        "${MAGEFLEET_ENV_PATH}/.magefleet/environments/${MAGEFLEET_ENV_TYPE}"
    )

    if [[ ${MAGEFLEET_MUTAGEN_ENABLE} -eq 0 ]]; then
        local FILE_SUFFIXES=(".base.yml" ".${MAGEFLEET_ENV_SUBT}.yml")
    else
        # Suffix .mutagen.yml is used for mutagen sync configuration
        # so using .mutagen_compose.yml for docker-compose configurations
        local FILE_SUFFIXES=(".base.yml" ".${MAGEFLEET_ENV_SUBT}.yml" ".mutagen_compose.yml")
    fi

    for BASE_PATH in "${BASE_PATHS[@]}"; do
        for SUFFIX in "${FILE_SUFFIXES[@]}"; do
            PARTIAL_PATH="${BASE_PATH}/${PARTIAL_NAME}${SUFFIX}"
            if [[ -f "${PARTIAL_PATH}" ]]; then
                DOCKER_COMPOSE_ARGS+=("-f" "${PARTIAL_PATH}")
            fi
        done
    done
}

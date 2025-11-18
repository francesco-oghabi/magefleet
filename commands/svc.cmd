#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${MAGEFLEET_DIR}/utils/install.sh"
assertWardenInstall
assertDockerRunning

if (( ${#MAGEFLEET_PARAMS[@]} == 0 )) || [[ "${MAGEFLEET_PARAMS[0]}" == "help" ]]; then
  $MAGEFLEET_BIN svc --help || exit $? && exit $?
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

## configure docker compose files
DOCKER_COMPOSE_ARGS=()

DOCKER_COMPOSE_ARGS+=("-f")
DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_DIR}/docker/docker-compose.yml")

if [[ -f "${MAGEFLEET_HOME_DIR}/.env" ]]; then
    # Check DNSMasq
    eval "$(grep "^MAGEFLEET_DNSMASQ_ENABLE" "${MAGEFLEET_HOME_DIR}/.env")"
    # Check Portainer
    eval "$(grep "^MAGEFLEET_PORTAINER_ENABLE" "${MAGEFLEET_HOME_DIR}/.env")"
    # Check PMA
    eval "$(grep "^MAGEFLEET_PHPMYADMIN_ENABLE" "${MAGEFLEET_HOME_DIR}/.env")"
fi

DOCKER_COMPOSE_ARGS+=("-f")
DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_DIR}/docker/docker-compose.mailpit.yml")

## add dnsmasq docker-compose
MAGEFLEET_DNSMASQ_ENABLE="${MAGEFLEET_DNSMASQ_ENABLE:-1}"
if [[ "$MAGEFLEET_DNSMASQ_ENABLE" == "1" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_DIR}/docker/docker-compose.dnsmasq.yml")
fi

MAGEFLEET_PORTAINER_ENABLE="${MAGEFLEET_PORTAINER_ENABLE:-0}"
if [[ "${MAGEFLEET_PORTAINER_ENABLE}" == 1 ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_DIR}/docker/docker-compose.portainer.yml")
fi

MAGEFLEET_PHPMYADMIN_ENABLE="${MAGEFLEET_PHPMYADMIN_ENABLE:-1}"
if [[ "${MAGEFLEET_PHPMYADMIN_ENABLE}" == 1 ]]; then
    if [[ -d "${MAGEFLEET_HOME_DIR}/etc/phpmyadmin/config.user.inc.php" ]]; then
        rm -rf ${MAGEFLEET_HOME_DIR}/etc/phpmyadmin/config.user.inc.php
    fi
    if [[ ! -f "${MAGEFLEET_HOME_DIR}/etc/phpmyadmin/config.user.inc.php" ]]; then
        mkdir -p "${MAGEFLEET_HOME_DIR}/etc/phpmyadmin"
        touch ${MAGEFLEET_HOME_DIR}/etc/phpmyadmin/config.user.inc.php
    fi
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_DIR}/docker/docker-compose.phpmyadmin.yml")
fi

## allow an additional docker-compose file to be loaded for global services
if [[ -f "${MAGEFLEET_HOME_DIR}/docker-compose.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${MAGEFLEET_HOME_DIR}/docker-compose.yml")
fi

## special handling when 'svc up' is run
if [[ "${MAGEFLEET_PARAMS[0]}" == "up" ]]; then

    ## sign certificate used by global services (by default warden.test)
    if [[ -f "${MAGEFLEET_HOME_DIR}/.env" ]]; then
        eval "$(grep "^MAGEFLEET_SERVICE_DOMAIN" "${MAGEFLEET_HOME_DIR}/.env")"
    fi

    MAGEFLEET_SERVICE_DOMAIN="${MAGEFLEET_SERVICE_DOMAIN:-warden.test}"
    if [[ ! -f "${MAGEFLEET_SSL_DIR}/certs/${MAGEFLEET_SERVICE_DOMAIN}.crt.pem" ]]; then
        "$MAGEFLEET_BIN" sign-certificate "${MAGEFLEET_SERVICE_DOMAIN}"
    fi

    ## copy configuration files into location where they'll be mounted into containers from
    mkdir -p "${MAGEFLEET_HOME_DIR}/etc/traefik"
    cp "${MAGEFLEET_DIR}/config/traefik/traefik.yml" "${MAGEFLEET_HOME_DIR}/etc/traefik/traefik.yml"

    ## generate dynamic traefik ssl termination configuration
    cat > "${MAGEFLEET_HOME_DIR}/etc/traefik/dynamic.yml" <<-EOT
		tls:
		  stores:
		    default:
		      defaultCertificate:
		        certFile: /etc/ssl/certs/magefleet/${MAGEFLEET_SERVICE_DOMAIN}.crt.pem
		        keyFile: /etc/ssl/certs/magefleet/${MAGEFLEET_SERVICE_DOMAIN}.key.pem
		  certificates:
	EOT

    for cert in $(find "${MAGEFLEET_SSL_DIR}/certs" -type f -name "*.crt.pem" | sed -E 's#^.*/ssl/certs/(.*)\.crt\.pem$#\1#'); do
        cat >> "${MAGEFLEET_HOME_DIR}/etc/traefik/dynamic.yml" <<-EOF
		    - certFile: /etc/ssl/certs/magefleet/${cert}.crt.pem
		      keyFile: /etc/ssl/certs/magefleet/${cert}.key.pem
		EOF
    done

    ## always execute svc up using --detach mode
    if ! (containsElement "-d" "$@" || containsElement "--detach" "$@"); then
        MAGEFLEET_PARAMS=("${MAGEFLEET_PARAMS[@]:1}")
        MAGEFLEET_PARAMS=(up -d "${MAGEFLEET_PARAMS[@]}")
    fi
fi

## pass ochestration through to docker compose
MAGEFLEET_SERVICE_DIR=${MAGEFLEET_DIR} ${DOCKER_COMPOSE_COMMAND} \
    --project-directory "${MAGEFLEET_HOME_DIR}" -p warden \
    "${DOCKER_COMPOSE_ARGS[@]}" "${MAGEFLEET_PARAMS[@]}" "$@"

## connect peered service containers to environment networks when 'svc up' is run
if [[ "${MAGEFLEET_PARAMS[0]}" == "up" ]]; then
    for network in $(docker network ls -f label=dev.magefleet.environment.name --format {{.Name}}); do
        connectPeeredServices "${network}"
    done

    if [[ "${MAGEFLEET_PHPMYADMIN_ENABLE}" == 1 ]]; then
        regeneratePMAConfig
    fi
fi

#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

mkdir -p "${MAGEFLEET_SSL_DIR}/certs"

if [[ ! -f "${MAGEFLEET_SSL_DIR}/rootca/certs/ca.cert.pem" ]]; then
  fatal "Missing the root CA file. Please run 'magefleet install' and try again."
fi

if (( ${#MAGEFLEET_PARAMS[@]} == 0 )); then
  echo -e "\033[33mCommand '${MAGEFLEET_CMD_VERB}' requires a hostname as an argument, please use --help for details."
  exit -1
fi

CERTIFICATE_SAN_LIST=
for (( i = 0; i < ${#MAGEFLEET_PARAMS[@]} * 2; i+=2 )); do
  [[ ${CERTIFICATE_SAN_LIST} ]] && CERTIFICATE_SAN_LIST+=","
  CERTIFICATE_SAN_LIST+="DNS.$(expr $i + 1):${MAGEFLEET_PARAMS[i/2]}"
  CERTIFICATE_SAN_LIST+=",DNS.$(expr $i + 2):*.${MAGEFLEET_PARAMS[i/2]}"
done

CERTIFICATE_NAME="${MAGEFLEET_PARAMS[0]}"

if [[ -f "${MAGEFLEET_SSL_DIR}/certs/${CERTIFICATE_NAME}.key.pem" ]]; then
    >&2 echo -e "\033[33mWarning: Certificate for ${CERTIFICATE_NAME} already exists! Overwriting...\033[0m\n"
fi

echo "==> Generating private key ${CERTIFICATE_NAME}.key.pem"
openssl genrsa -out "${MAGEFLEET_SSL_DIR}/certs/${CERTIFICATE_NAME}.key.pem" 2048

echo "==> Generating signing req ${CERTIFICATE_NAME}.crt.pem"
openssl req -new -sha256 -config <(cat                            \
    "${MAGEFLEET_DIR}/config/openssl/certificate.conf"               \
    <(printf "extendedKeyUsage = serverAuth,clientAuth \n         \
      subjectAltName = %s" "${CERTIFICATE_SAN_LIST}")             \
  )                                                               \
  -key "${MAGEFLEET_SSL_DIR}/certs/${CERTIFICATE_NAME}.key.pem"      \
  -out "${MAGEFLEET_SSL_DIR}/certs/${CERTIFICATE_NAME}.csr.pem"      \
  -subj "/C=US/O=Warden.dev/CN=${CERTIFICATE_NAME}"

echo "==> Generating certificate ${CERTIFICATE_NAME}.crt.pem"
openssl x509 -req -days 365 -sha256 -extensions v3_req            \
  -extfile <(cat                                                  \
    "${MAGEFLEET_DIR}/config/openssl/certificate.conf"               \
    <(printf "extendedKeyUsage = serverAuth,clientAuth \n         \
      subjectAltName = %s" "${CERTIFICATE_SAN_LIST}")             \
  )                                                               \
  -CA "${MAGEFLEET_SSL_DIR}/rootca/certs/ca.cert.pem"                \
  -CAkey "${MAGEFLEET_SSL_DIR}/rootca/private/ca.key.pem"            \
  -CAserial "${MAGEFLEET_SSL_DIR}/rootca/serial"                     \
  -in "${MAGEFLEET_SSL_DIR}/certs/${CERTIFICATE_NAME}.csr.pem"       \
  -out "${MAGEFLEET_SSL_DIR}/certs/${CERTIFICATE_NAME}.crt.pem" 

if [[ "$(cd "${MAGEFLEET_HOME_DIR}" && ${DOCKER_COMPOSE_COMMAND} -p warden -f "${MAGEFLEET_DIR}/docker/docker-compose.yml" ps -q traefik)" ]]
then
  echo "==> Updating traefik"
  "$MAGEFLEET_BIN" svc up traefik
  "$MAGEFLEET_BIN" svc restart traefik
fi

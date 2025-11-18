#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${MAGEFLEET_ENV_PATH}" || exit $?

if [[ ${MAGEFLEET_SELENIUM} -ne 1 ]] || [[ ${MAGEFLEET_SELENIUM_DEBUG} -ne 1 ]]; then
  fatal "The project environment must have MAGEFLEET_SELENIUM and MAGEFLEET_SELENIUM_DEBUG enabled to use this command"
fi

MAGEFLEET_SELENIUM_INDEX=${MAGEFLEET_PARAMS[0]:-1}
MAGEFLEET_SELENIUM_VNC=${MAGEFLEET_ENV_NAME}-${MAGEFLEET_PARAMS[1]:-selenium}-${MAGEFLEET_SELENIUM_INDEX}

if ! which remmina >/dev/null; then
  EXPOSE_PORT=$((5900 + MAGEFLEET_SELENIUM_INDEX))

  echo "Connect with your VNC client to 127.0.0.1:${EXPOSE_PORT}"
  echo "    Password: secret"
  echo "You can also use URL: vnc://127.0.0.1:${EXPOSE_PORT}/?VncPassword=secret"
  ssh -N -L localhost:${EXPOSE_PORT}:${MAGEFLEET_SELENIUM_VNC}:5900 tunnel.magefleet.test
else

  cat > "${MAGEFLEET_ENV_PATH}/.remmina" <<-EOF
	[remmina]
	name=${MAGEFLEET_SELENIUM_VNC} Debug
	proxy=
	ssh_enabled=1
	colordepth=8
	server=${MAGEFLEET_SELENIUM_VNC}
	ssh_auth=3
	quality=9
	scale=1
	ssh_username=user
	password=.
	disablepasswordstoring=0
	viewmode=1
	window_width=1200
	window_height=780
	ssh_server=tunnel.magefleet.test:2222
	protocol=VNC
	EOF

  echo -e "Launching VNC session via Remmina. Password is \"\033[1msecret\"\033[0m"
  remmina -c "${MAGEFLEET_ENV_PATH}/.remmina"
fi

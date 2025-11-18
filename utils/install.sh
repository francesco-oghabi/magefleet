#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function installSshConfig () {
  if ! grep '## WARDEN START ##' /etc/ssh/ssh_config >/dev/null; then
    echo "==> Configuring sshd tunnel in host ssh_config (requires sudo privileges)"
    echo "    Note: This addition to the ssh_config file can sometimes be erased by a system"
    echo "    upgrade requiring reconfiguring the SSH config for tunnel.magefleet.test."
    cat <<-EOT | sudo tee -a /etc/ssh/ssh_config >/dev/null

			## WARDEN START ##
			Host tunnel.magefleet.test
			HostName 127.0.0.1
			User user
			Port 2222
			IdentityFile ~/.magefleet/tunnel/ssh_key
			## WARDEN END ##
			EOT
  fi
}

function assertWardenInstall {
  if [[ ! -f "${MAGEFLEET_HOME_DIR}/.installed" ]] \
    || [[ "${MAGEFLEET_HOME_DIR}/.installed" -ot "${MAGEFLEET_DIR}/bin/magefleet" ]]
  then
    [[ -f "${MAGEFLEET_HOME_DIR}/.installed" ]] && echo "==> Updating warden" || echo "==> Starting initialization"

    "${MAGEFLEET_DIR}/bin/magefleet" install

    [[ -f "${MAGEFLEET_HOME_DIR}/.installed" ]] && echo "==> Update complete" || echo "==> Initialization complete"
    date > "${MAGEFLEET_HOME_DIR}/.installed"
  fi

  ## append settings for tunnel.magefleet.test in /etc/ssh/ssh_config
  #
  # NOTE: This function is called on every invocation of this assertion in an attempt to ensure
  # the ssh configuration for the tunnel is present following it's removal following a system
  # upgrade (macOS Catalina has been found to reset the global SSH configuration file)
  #

  installSshConfig
}

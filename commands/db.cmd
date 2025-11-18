#!/usr/bin/env bash
[[ ! ${MAGEFLEET_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

MAGEFLEET_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${MAGEFLEET_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${MAGEFLEET_DB:-1} -eq 0 ]]; then
  fatal "Database environment is not used (MAGEFLEET_DB=0)."
fi

if (( ${#MAGEFLEET_PARAMS[@]} == 0 )) || [[ "${MAGEFLEET_PARAMS[0]}" == "help" ]]; then
  $MAGEFLEET_BIN db --help || exit $? && exit $?
fi

## load connection information for the mysql service
DB_CONTAINER=$($MAGEFLEET_BIN env ps -q db)
if [[ ! ${DB_CONTAINER} ]]; then
    fatal "No container found for db service."
fi

eval "$(
    docker container inspect ${DB_CONTAINER} --format '
        {{- range .Config.Env }}{{with split . "=" -}}
            {{- index . 0 }}='\''{{ range $i, $v := . }}{{ if $i }}{{ $v }}{{ end }}{{ end }}'\''{{println}}
        {{- end }}{{ end -}}
    ' | grep "^MYSQL_"
)"

## sub-command execution
case "${MAGEFLEET_PARAMS[0]}" in
    connect)
        "$MAGEFLEET_BIN" env exec db \
            mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" "${MAGEFLEET_PARAMS[@]:1}" "$@"
        ;;
    import)
        LC_ALL=C sed -E 's/DEFINER[ ]*=[ ]*`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' \
            | LC_ALL=C sed -E '/\@\@(GLOBAL\.GTID_PURGED|SESSION\.SQL_LOG_BIN)/d' \
            | "$MAGEFLEET_BIN" env exec -T db \
            mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" "${MAGEFLEET_PARAMS[@]:1}" "$@"
        ;;
    dump)
            "$MAGEFLEET_BIN" env exec -T db \
            mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" "${MAGEFLEET_PARAMS[@]:1}" "$@"
        ;;
    *)
        fatal "The command \"${MAGEFLEET_PARAMS[0]}\" does not exist. Please use --help for usage."
        ;;
esac

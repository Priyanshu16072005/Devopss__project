#!/usr/bin/env bash
# Start Apache (web interface) and Nagios Core in one container.
set -euo pipefail

NAGIOS_HOME="${NAGIOS_HOME:-/usr/local/nagios}"
CFG="${NAGIOS_HOME}/etc/nagios.cfg"

# Login for the web interface (user: nagiosadmin)
htpasswd -bc "${NAGIOS_HOME}/etc/htpasswd.users" nagiosadmin "${NAGIOSADMIN_PASSWORD:-nagiosadmin}"

# The var/ folder is a Docker volume: make sure every directory exists
mkdir -p "${NAGIOS_HOME}/var/rw" "${NAGIOS_HOME}/var/archives" "${NAGIOS_HOME}/var/spool/checkresults"
chown -R nagios:nagios "${NAGIOS_HOME}/var"
chmod 2775 "${NAGIOS_HOME}/var/rw"     # Apache (group nagios) writes commands here
rm -f "${NAGIOS_HOME}/var/nagios.lock" "${NAGIOS_HOME}/var/rw/nagios.cmd"

# Refuse to start with a broken configuration
"${NAGIOS_HOME}/bin/nagios" -v "${CFG}" | tail -n 4

apachectl start
echo "Web interface: http://localhost:8081/nagios  (user nagiosadmin)"

# Show the Nagios log in `docker compose logs nagios`
touch "${NAGIOS_HOME}/var/nagios.log" && chown nagios:nagios "${NAGIOS_HOME}/var/nagios.log"
tail -F "${NAGIOS_HOME}/var/nagios.log" &

# Nagios in the foreground (it drops root privileges to the nagios user)
exec "${NAGIOS_HOME}/bin/nagios" "${CFG}"

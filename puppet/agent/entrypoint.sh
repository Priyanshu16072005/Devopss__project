#!/usr/bin/env bash
# Entrypoint for Puppet client containers.
#
#   no arguments  -> agent mode: connect to the Puppet master, get the
#                    certificate signed by its CA, then pull and apply
#                    the catalog every RUNINTERVAL seconds (PULL model)
#   any arguments -> run that command instead, e.g.
#                    `puppet apply ...`, `facter`, `bash`
set -euo pipefail

PUPPET_SERVER="${PUPPET_SERVER:-puppet}"
CERTNAME="${CERTNAME:-$(hostname -f)}"
RUNINTERVAL="${RUNINTERVAL:-120}"
ENVIRONMENT="${PUPPET_ENVIRONMENT:-production}"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# Write the agent settings into /etc/puppetlabs/puppet/puppet.conf [agent]
puppet config set server      "$PUPPET_SERVER" --section main
puppet config set certname    "$CERTNAME"      --section main
puppet config set environment "$ENVIRONMENT"   --section agent
puppet config set runinterval "$RUNINTERVAL"   --section agent

echo "[entrypoint] certname=${CERTNAME} server=${PUPPET_SERVER} runinterval=${RUNINTERVAL}s"

# Wait until the Puppet master answers on port 8140
until (exec 3<>"/dev/tcp/${PUPPET_SERVER}/8140") 2>/dev/null; do
  echo "[entrypoint] waiting for Puppet master ${PUPPET_SERVER}:8140 ..."
  sleep 5
done

# Run in the foreground; --waitforcert keeps retrying until the CA signs our CSR
exec puppet agent --no-daemonize --verbose --waitforcert 15

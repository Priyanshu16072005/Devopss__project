# =============================================================
#  Puppet CLIENT node (Puppet Agent + Facter) as a container.
#  Used for web1, web2 and lb (agent/pull mode).
#
#  OpenVox is the open-source, drop-in continuation of Puppet
#  (same `puppet` command, same manifests, same /etc/puppetlabs paths).
# =============================================================
FROM ubuntu:24.04

ARG OPENVOX_RELEASE=8
ARG UBUNTU_VERSION=24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/puppetlabs/bin:$PATH

# 1. Prerequisites
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl iproute2 procps \
 && rm -rf /var/lib/apt/lists/*

# 2. Installation of Puppet: add the OpenVox apt repository, then install the agent
#    (equivalent of the classic `puppet8-release` + `apt-get install puppet-agent`)
ADD https://apt.voxpupuli.org/openvox${OPENVOX_RELEASE}-release-ubuntu${UBUNTU_VERSION}.deb /tmp/openvox-release.deb
RUN apt-get update \
 && apt-get install -y --no-install-recommends /tmp/openvox-release.deb \
 && apt-get update \
 && apt-get install -y --no-install-recommends openvox-agent \
 && rm -f /tmp/openvox-release.deb \
 && puppet --version && facter --version
# NOTE: apt lists are kept on purpose - Puppet installs nginx/haproxy at runtime.

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /puppet
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# No arguments = run as an agent that PULLS its catalog from the Puppet master
CMD []

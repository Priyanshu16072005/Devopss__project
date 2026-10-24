# =============================================================
#  Nagios Core 4 + Nagios Plugins, COMPILED FROM SOURCE,
#  served by Apache (web interface at /nagios).
#
#  Each RUN step below is one step of the classic manual install:
#    1. install prerequisites   2. compile & install Nagios Core
#    3. set up the web server   4. compile & install the plugins
# =============================================================
FROM ubuntu:24.04

ARG NAGIOS_VERSION=4.5.14
ARG PLUGINS_VERSION=2.4.12
ENV DEBIAN_FRONTEND=noninteractive \
    NAGIOS_HOME=/usr/local/nagios

# ---------- 1. Prerequisites: compiler, Apache, PHP, GD, OpenSSL ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
      autoconf gcc libc6 make wget unzip ca-certificates \
      apache2 apache2-utils php libapache2-mod-php libgd-dev \
      openssl libssl-dev \
      # needed by the plugins (check_ping, check_http, check_tcp ...)
      bc gawk dc iputils-ping procps gettext \
 && rm -rf /var/lib/apt/lists/*

# ---------- 2. Compile & install Nagios Core ----------
WORKDIR /tmp/build
RUN wget -q https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz \
 && tar xzf nagios-${NAGIOS_VERSION}.tar.gz \
 && cd nagios-${NAGIOS_VERSION} \
 && ./configure --with-httpd-conf=/etc/apache2/sites-enabled \
 && make all \
 # create the nagios user/group, let Apache submit commands
 && make install-groups-users \
 && usermod -a -G nagios www-data \
 # binaries, CGIs, HTML
 && make install \
 # external command file (used by the web UI)
 && make install-commandmode \
 # sample config in /usr/local/nagios/etc
 && make install-config \
 # ---------- 3. Web server: Apache config for /nagios ----------
 && make install-webconf \
 && a2enmod rewrite cgi \
 && cd / && rm -rf /tmp/build

# ---------- 4. Compile & install the Nagios Plugins ----------
WORKDIR /tmp/build
RUN wget -q https://github.com/nagios-plugins/nagios-plugins/releases/download/release-${PLUGINS_VERSION}/nagios-plugins-${PLUGINS_VERSION}.tar.gz \
 && tar xzf nagios-plugins-${PLUGINS_VERSION}.tar.gz \
 && cd nagios-plugins-${PLUGINS_VERSION} \
 && ./configure --with-nagios-user=nagios --with-nagios-group=nagios \
 && make \
 && make install \
 && cd / && rm -rf /tmp/build

# ---------- Food For All monitoring configuration ----------
COPY etc/objects/foodforall/ ${NAGIOS_HOME}/etc/objects/foodforall/
# Load our folder and drop the sample localhost.cfg
RUN sed -i 's#^cfg_file=/usr/local/nagios/etc/objects/localhost.cfg#\#&#' ${NAGIOS_HOME}/etc/nagios.cfg \
 && echo "cfg_dir=${NAGIOS_HOME}/etc/objects/foodforall" >> ${NAGIOS_HOME}/etc/nagios.cfg \
 && chown -R nagios:nagios ${NAGIOS_HOME}/etc \
 # fail the image build if the configuration has an error
 && ${NAGIOS_HOME}/bin/nagios -v ${NAGIOS_HOME}/etc/nagios.cfg

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR ${NAGIOS_HOME}
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD pgrep -x nagios >/dev/null && wget -qO /dev/null http://127.0.0.1/ || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Nginx web server that serves the Food For All app.
#
# @param site_color Colour of the /node/ page (different on web1 and web2)
class webserver (
  String $site_color = '#2e7d32',
) {
  package { 'nginx':
    ensure => installed,
  }

  # Our site config, built from a template
  file { '/etc/nginx/sites-enabled/foodforall.conf':
    ensure  => file,
    content => epp('webserver/vhost.conf.epp'),
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  # Remove the default Nginx site
  file { '/etc/nginx/sites-enabled/default':
    ensure  => absent,
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  # Small page that shows which server answered
  file { '/var/www/node':
    ensure  => directory,
    require => Package['nginx'],
  }

  file { '/var/www/node/index.html':
    ensure  => file,
    content => epp('webserver/node-info.html.epp', { 'color' => $site_color }),
  }

  # Containers have no systemd, so we give Puppet the commands to use
  service { 'nginx':
    ensure   => running,
    provider => 'base',
    start    => '/usr/sbin/nginx',
    stop     => '/usr/sbin/nginx -s quit',
    restart  => '/usr/sbin/nginx -s reload',
    status   => '/usr/bin/pgrep -x nginx',
    require  => Package['nginx'],
  }
}

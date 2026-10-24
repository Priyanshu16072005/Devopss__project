# HAProxy load balancer in front of the web servers.
#
# @param backends The web servers to share traffic between
class loadbalancer (
  Array[String] $backends = ['web1.foodforall.local', 'web2.foodforall.local'],
) {
  package { 'haproxy':
    ensure => installed,
  }

  file { '/etc/haproxy/haproxy.cfg':
    ensure  => file,
    content => epp('loadbalancer/haproxy.cfg.epp', { 'backends' => $backends }),
    require => Package['haproxy'],
    notify  => Service['haproxy'],
  }

  # Containers have no systemd, so we give Puppet the commands to use
  service { 'haproxy':
    ensure   => running,
    provider => 'base',
    start    => '/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -D -p /run/haproxy.pid',
    stop     => "/bin/sh -c 'kill $(cat /run/haproxy.pid)'",
    restart  => "/bin/sh -c '/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -D -p /run/haproxy.pid -sf $(cat /run/haproxy.pid)'",
    status   => '/usr/bin/pgrep -x haproxy',
    require  => Package['haproxy'],
  }
}

# Common setup for every Food For All server:
# a few tools, an ops user and a login message.
class foodforall {
  package { ['curl', 'vim-tiny']:
    ensure => installed,
  }

  user { 'foodops':
    ensure     => present,
    shell      => '/bin/bash',
    managehome => true,
  }

  # Login message. If someone edits this file by hand,
  # Puppet puts it back on the next run.
  file { '/etc/motd':
    ensure  => file,
    mode    => '0644',
    content => epp('foodforall/motd.epp'),
  }
}

# 
class postfix::cf ( 
  Hash $main    = {}, 
  Array $master = [],
  String $tempdir,
) {
  # merge default parameters with the given parameters
  $config = deep_merge($main, $postfix::params::defaults)

  # merging transports
  $transports = union($master, $postfix::params::default_transports)
  
  file { "${tempdir}":
    ensure => directory,
    mode   => "0777"
  }->
  # creating configuration files in them directory
  # and checking the syntax
  file { "${tempdir}/main.cf":
    ensure  => file,
    content => template('postfix/main.cf.dynamic.erb'),
  }->
  exec { 'check-main.cf':
    command     => "/usr/sbin/postconf -df -c ${tempdir}",
    subscribe   => File["${tempdir}/main.cf"],
    refreshonly => true
  }
  file { "${tempdir}/master.cf":
    ensure  => file,
    content => template('postfix/master.cf.erb'),
  }->
  exec { 'check-master.cf':
    command     => "/usr/sbin/postconf -Mf -c ${tempdir} && /usr/sbin/postconf -Mf -c ${tempdir} > ${tempdir}/master.cf.new", 
    subscribe   => File["${tempdir}/master.cf"],
    refreshonly => true,
  }

  # if they looked fine push them to postfix directory
  file { '/etc/postfix/master.cf':
    source    => "file://${tempdir}/master.cf.new",
    notify      => Service['postfix'],
    subscribe   => Exec['check-master.cf'],
  }
  file { '/etc/postfix/main.cf':
    source    => "file://${tempdir}/main.cf",
    notify    => Service['postfix'],
    subscribe => Exec['check-main.cf']
  }
}

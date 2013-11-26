
# Ensure the time is accurate, reducing the possibilities of apt repositories
# failing for invalid certificates
include '::ntp'

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/", "/usr/local/sbin" ] }
File { owner => 0, group => 0, mode => 0644 }

# Fix qualified domain
if $virtual == "virtualbox" and $fqdn == '' {
  $fqdn = 'localhost'
}

# Build default values from hiera
if $server_values == undef {
  $server_values = hiera('server', false)
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

if $apache_values == undef {
  $apache_values = hiera('apache', false)
}

if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}

if $xdebug_values == undef {
  $xdebug_values = hiera('xdebug', false)
}

if $xhprof_values == undef {
  $xhprof_values = hiera('xhprof', false)
}

if $mysql_values == undef {
  $mysql_values = hiera('mysql', false)
}

if $postgresql_values == undef {
  $postgresql_values = hiera('postgresql', false)
}

if $node_values == undef {
  $node_values = hiera('node', false)
}

if $ngrok_values == undef {
  $ngrok_values = hiera('ngrok', false)
}

if $application_values == undef {
  $application_values = hiera('application', false)
}

# Make sure apache and nginx are both not running
if is_hash($apache_values) and $apache_values['install'] == 1 and
   is_hash($nginx_values) and $nginx_values['install'] == 1 {
  fail( 'Apache and Nginx can\'t both be installed!' )
}

# Make sure puppet and www-data groups exist
group { 'puppet': ensure => present }
group { 'www-data': ensure => present }

# Make sure ssh user exists, setup in vagrant file
user { $::ssh_username:
  shell  => '/bin/bash',
  home   => "/home/${::ssh_username}",
  ensure => present
}

# Make sure common web server users are in www-data group
user { ['apache', 'nginx', 'httpd', 'www-data']:
  shell  => '/bin/bash',
  ensure => present,
  groups => 'www-data',
  require => Group['www-data']
}

# Make sure ssh user has a home directory
file { "/home/${::ssh_username}":
    ensure => directory,
    owner  => $::ssh_username,
}

# Make sure ssh user has ssh folder
file { "/home/${::ssh_username}/.ssh":
  ensure => directory,
  mode   => 0700,
  owner  => $::ssh_username,
  group  => $::ssh_username,
  require => File["/home/${::ssh_username}"],
}

# copy dot files to ssh user's home directory
exec { 'dotfiles':
  cwd     => "/home/${::ssh_username}",
  command => "cp -r /vagrant/files/dot/.[a-zA-Z0-9]* /home/${::ssh_username}/ && chown -R ${::ssh_username} /home/${::ssh_username}/.[a-zA-Z0-9]*",
  onlyif  => "test -d /vagrant/files/dot",
  require => User[$::ssh_username]
}

# common setup
case $::osfamily {
  # debian, ubuntu
  'debian': {
    class { 'apt': }

    Class['::apt::update'] -> Package <|
        title != 'python-software-properties'
    and title != 'software-properties-common'
    |>

    ensure_packages( ['augeas-tools'] )
  }
  # redhat, centos
  'redhat': {
    class { 'yum': extrarepo => ['epel'] }

    Class['::yum'] -> Yum::Managed_yumrepo <| |> -> Package <| |>

    exec { 'bash_git':
      cwd     => "/home/${::ssh_username}",
      command => "curl https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh > /home/${::ssh_username}/.bash_git",
      creates => "/home/${::ssh_username}/.bash_git"
    }

    file_line { 'link ~/.bash_git':
      ensure  => present,
      line    => 'if [ -f ~/.bash_git ] ; then source ~/.bash_git; fi',
      path    => "/home/${::ssh_username}/.bash_profile",
      require => [
        Exec['dotfiles'],
        Exec['bash_git'],
      ]
    }

    file_line { 'link ~/.bash_aliases':
      ensure  => present,
      line    => 'if [ -f ~/.bash_aliases ] ; then source ~/.bash_aliases; fi',
      path    => "/home/${::ssh_username}/.bash_profile",
      require => [
        File_line['link ~/.bash_git'],
      ]
    }

    ensure_packages( ['augeas'] )
  }
}

## Begin Server manifest

if is_hash($server_values) {

  #ssh configuration
  if is_hash($server_values['ssh']) {

    #ssh authorized keys
    if is_hash($server_values['ssh']['authorized_keys']) {

      file { "/home/${::ssh_username}/.ssh/authorized_keys":
        ensure => present,
        mode   => 0600,
        owner  => $::ssh_username,
        group  => $::ssh_username,
        require => File["/home/${::ssh_username}/.ssh"],
      }

      $server_values['ssh']['authorized_keys'].each |$key, $value| {
        if $value['key_file'] != undef {
          # copy authorized keys to system
          $path = $value['key_file']
          exec { "ssh_authorized_key_file-${key}": 
            command => "/bin/cat ${path} >> /home/${::ssh_username}/.ssh/authorized_keys",
            onlyif  => "test -f ${path}",
            require => File["/home/${::ssh_username}/.ssh/authorized_keys"],
          }
        } else {
          if $value['options'] != undef {
            $options = $value['options']
          } else {
            $options = undef
          }

          if $value['target'] != undef {
            $target = $value['target']
          } else {
            $target = "/home/${::ssh_username}/.ssh/authorized_keys"
          }

          if $value['type'] != undef {
            $type = $value['type']
          } else {
            $type = 'ssh-rsa'
          }

          if $value['user'] != undef {
            $user = $value['user']
          } else {
            $user = $::ssh_username
          }

          ssh_authorized_key { 'ssh_authorized_key-${key}':
            ensure   => present,
            key      => $value['key'],
            options  => $options,
            target   => $target,
            type     => $type,
            user     => $user,
            require  => File["/home/${::ssh_username}/.ssh/authorized_keys"],
          }
        }
      }
    }

    #ssh config
    if is_hash($server_values['ssh']['config']) {

      # Make sure ssh user has ssh config
      file { "/home/${::ssh_username}/.ssh/config":
        ensure => present,
        mode   => 0600,
        owner  => $::ssh_username,
        group  => $::ssh_username,
        require => File["/home/${::ssh_username}/.ssh"],
      }

      $server_values['ssh']['config'].each |$key, $value| {
        if $value['config_file'] != undef {
          #add entries from file
          $path = $value['config_file']
          exec { "ssh_config_file-${key}": 
            command => "/bin/cat ${path} >> /home/${::ssh_username}/.ssh/config",
            onlyif  => "test -f ${path}",
            require => File["/home/${::ssh_username}/.ssh/config"],
          }
        } else {
          #add single config entries
          $text = $value['config']
          exec { "ssh_config-${key}": 
            command => "echo \"${text}\" >> /home/${::ssh_username}/.ssh/config",
            require => File["/home/${::ssh_username}/.ssh/config"],
          }
        }
      }
    }

    #ssh keys
    if is_hash($server_values['ssh']['keys']) {

      $server_values['ssh']['keys'].each |$key, $value| {
        if $value['key_file'] != undef {
          # copy keys to system
          $path = $value['key_file']

          if $value['filename'] != undef {
            $filename = $value['filename']
          } else {
            $filename = 'id_rsa'
          }

          if ! defined(File["/home/${::ssh_username}/.ssh/${filename}"]) {
            file { "/home/${::ssh_username}/.ssh/${filename}":
              ensure => file,
              mode   => 0600,
              owner  => $::ssh_username,
              group  => $::ssh_username,
              require => File["/home/${::ssh_username}/.ssh"],
            }
          }

          exec { "ssh_key_file-${key}": 
            command => "/bin/cp ${path} /home/${::ssh_username}/.ssh/${filename}",
            onlyif  => "test -f ${path}",
            require => File["/home/${::ssh_username}/.ssh/${filename}"],
          }
        } else {
          #add single ssh key

          if $value['host_aliases'] != undef {
            $host_aliases = $value['host_aliases']
          } else {
            $host_aliases = ''
          }

          if $value['target'] != undef {
            $target = $value['target']
          } else {
            $target = "/home/${::ssh_username}/.ssh/id_rsa"
          }

          if $value['type'] != undef {
            $key_type = $value['type']
          } else {
            $key_type = 'ssh-rsa'
          }

          sshkey { 'ssh_key-${key}':
            ensure       => present,
            key          => $value['key'],
            host_aliases => $host_aliases,
            target       => $target,
            type         => $key_type,
          }
        }
      }
    }
  }

  # server packages
  if !empty($server_values['packages']) {
    ensure_packages( $server_values['packages'] )
  }
}

## Begin PHP manifest

# update PHP version repo
case $::operatingsystem {
  'debian': {
    add_dotdeb { 'packages.dotdeb.org': release => $lsbdistcodename }

    if is_hash($php_values) {
      # Debian Squeeze 6.0 can do PHP 5.3 (default) and 5.4
      if $lsbdistcodename == 'squeeze' and $php_values['version'] == '54' {
        add_dotdeb { 'packages.dotdeb.org-php54': release => 'squeeze-php54' }
      }
      # Debian Wheezy 7.0 can do PHP 5.4 (default) and 5.5
      elsif $lsbdistcodename == 'wheezy' and $php_values['version'] == '55' {
        add_dotdeb { 'packages.dotdeb.org-php55': release => 'wheezy-php55' }
      }
    }
  }
  'ubuntu': {
    apt::key { '4F4EA0AAE5267A6C': }

    if is_hash($php_values) {
      # Ubuntu Lucid 10.04, Precise 12.04, Quantal 12.10 and Raring 13.04 can do PHP 5.3 (default <= 12.10) and 5.4 (default <= 13.04)
      if $lsbdistcodename in ['lucid', 'precise', 'quantal', 'raring'] and $php_values['version'] == '54' {
        if $lsbdistcodename == 'lucid' {
          apt::ppa { 'ppa:ondrej/php5-oldstable': require => Apt::Key['4F4EA0AAE5267A6C'], options => '' }
        } else {
          apt::ppa { 'ppa:ondrej/php5-oldstable': require => Apt::Key['4F4EA0AAE5267A6C'] }
        }
      }
      # Ubuntu Precise 12.04, Quantal 12.10 and Raring 13.04 can do PHP 5.5
      elsif $lsbdistcodename in ['precise', 'quantal', 'raring'] and $php_values['version'] == '55' {
        apt::ppa { 'ppa:ondrej/php5': require => Apt::Key['4F4EA0AAE5267A6C'] }
      }
      elsif $lsbdistcodename in ['lucid'] and $php_values['version'] == '55' {
        err('You have chosen to install PHP 5.5 on Ubuntu 10.04 Lucid. This will probably not work!')
      }
    }
  }
  'redhat', 'centos': {
    if is_hash($php_values) {
      if $php_values['version'] == '54' {
        class { 'yum::repo::remi': }
      }
      # remi_php55 requires the remi repo as well
      elsif $php_values['version'] == '55' {
        class { 'yum::repo::remi': }
        class { 'yum::repo::remi_php55': }
      }
    }
  }
}

define add_dotdeb ($release){
   apt::source { $name:
    location          => 'http://packages.dotdeb.org',
    release           => $release,
    repos             => 'all',
    required_packages => 'debian-keyring debian-archive-keyring',
    key               => '89DF5277',
    key_server        => 'keys.gnupg.net',
    include_src       => true
  }
}

## Begin Apache manifest

include puphpet::params

$webroot_location = $puphpet::params::apache_webroot_location

# Create web root if it does not exist
exec { "exec mkdir -p ${webroot_location}":
  command => "mkdir -p ${webroot_location}",
  onlyif  => "test -d ${webroot_location}",
}

# Ensure the directory is created with the right ownership
if ! defined(File[$webroot_location]) {
  file { $webroot_location:
    ensure  => directory,
    group   => 'www-data',
    mode    => 0775,
    require => [
      Exec["exec mkdir -p ${webroot_location}"],
      Group['www-data']
    ]
  }
}

# Setup apache class
class { 'apache':
  user          => $apache_values['user'],
  group         => $apache_values['group'],
  default_vhost => $apache_values['default_vhost'],
  mpm_module    => $apache_values['mpm_module'],
  manage_user   => false,
  manage_group  => false
}

# Setup the workers
if $::osfamily == 'debian' {
  case $apache_values['mpm_module'] {
    'prefork': { ensure_packages( ['apache2-mpm-prefork'] ) }
    'worker':  { ensure_packages( ['apache2-mpm-worker'] ) }
    'event':   { ensure_packages( ['apache2-mpm-event'] ) }
  }
} elsif $::osfamily == 'redhat' and ! defined(Iptables::Allow['tcp/80']) {
  iptables::allow { 'tcp/80':
    port     => '80',
    protocol => 'tcp'
  }
}

# setup the virtualhosts
create_resources(apache::vhost, $apache_values['vhosts'])

# setup apache modules
define apache_mod {
  if ! defined(Class["apache::mod::${name}"]) {
    class { "apache::mod::${name}": }
  }
}

if count($apache_values['modules']) > 0 {
  apache_mod { $apache_values['modules']: }
}

## Begin PHP manifest

Class['Php'] -> Class['Php::Devel'] -> Php::Module <| |> -> Php::Pear::Module <| |> -> Php::Pecl::Module <| |>

if $php_prefix == undef {
  $php_prefix = $::operatingsystem ? {
    /(?i:Ubuntu|Debian|Mint|SLES|OpenSuSE)/ => 'php5-',
    default                                 => 'php-',
  }
}

if $php_fpm_ini == undef {
  $php_fpm_ini = $::operatingsystem ? {
    /(?i:Ubuntu|Debian|Mint|SLES|OpenSuSE)/ => '/etc/php5/fpm/php.ini',
    default                                 => '/etc/php.ini',
  }
}

if is_hash($apache_values) and $apache_values['install'] == 1 {
  include apache::params

  $php_webserver_service = 'httpd'
  $php_webserver_user = $apache::params::user

  class { 'php':
    service => $php_webserver_service
  }
} elsif is_hash($nginx_values) and $nginx_values['install'] == 1 {
  include nginx::params

  $php_webserver_service = "${php_prefix}fpm"
  $php_webserver_user = $nginx::params::nx_daemon_user

  class { 'php':
    package             => $php_webserver_service,
    service             => $php_webserver_service,
    service_autorestart => false,
    config_file         => $php_fpm_ini,
  }

  service { $php_webserver_service:
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package[$php_webserver_service]
  }
}

class { 'php::devel': }

if count($php_values['modules']['php']) > 0 {
  php_mod { $php_values['modules']['php']:; }
}
if count($php_values['modules']['pear']) > 0 {
  php_pear_mod { $php_values['modules']['pear']:; }
}
if count($php_values['modules']['pecl']) > 0 {
  php_pecl_mod { $php_values['modules']['pecl']:; }
}
if count($php_values['ini']) > 0 {
  $php_values['ini'].each |$key, $value| {
    puphpet::ini { $key:
      entry       => "CUSTOM/${key}",
      value       => $value,
      php_version => $php_values['version'],
      webserver   => $php_webserver_service
    }
  }

  if $php_values['ini']['session.save_path'] != undef {
    exec {"mkdir -p ${php_values['ini']['session.save_path']}":
      onlyif  => "test ! -d ${php_values['ini']['session.save_path']}",
    }

    file { $php_values['ini']['session.save_path']:
      ensure  => directory,
      group   => 'www-data',
      mode    => 0775,
      require => Exec["mkdir -p ${php_values['ini']['session.save_path']}"]
    }
  }
}

puphpet::ini { $key:
  entry       => 'CUSTOM/date.timezone',
  value       => $php_values['timezone'],
  php_version => $php_values['version'],
  webserver   => $php_webserver_service
}

define php_mod {
  php::module { $name: }
}
define php_pear_mod {
  php::pear::module { $name: use_package => false }
}
define php_pecl_mod {
  php::pecl::module { $name: use_package => false }
}

# install composer if needed
if $php_values['composer'] == 1 {
  add_composer { "composer": }
}

define add_composer (
  $path = ''
){
  class { 'composer':
    target_dir      => '/usr/local/bin',
    composer_file   => 'composer',
    download_method => 'curl',
    logoutput       => false,
    tmp_path        => '/tmp',
    php_package     => "${php::params::module_prefix}cli",
    curl_package    => 'curl',
    suhosin_enabled => false,
  }
}

## Begin XDebug

if is_hash($xdebug_values) and $xdebug_values['install'] != undef and $xdebug_values['install'] == 1 {
  class { 'puphpet::xdebug':
    webserver => $php_webserver_service
  }

  if is_hash($xdebug_values['settings']) and count($xdebug_values['settings']) > 0 {
    $xdebug_values['settings'].each |$key, $value| {
      puphpet::ini { $key:
        entry       => "XDEBUG/${key}",
        value       => $value,
        php_version => $php_values['version'],
        webserver   => $php_webserver_service
      }
    }
  }
}

## Begin Xhprof manifest

if is_hash($xhprof_values) and $xhprof_values['install'] == 1 {
  $xhprofPath = $xhprof_values['location']

  php::pecl::module { 'xhprof':
    use_package     => false,
    preferred_state => 'beta',
  }

  exec { 'delete-xhprof-path-if-not-git-repo':
    command => "rm -rf ${xhprofPath}",
    onlyif => "test ! -d ${xhprofPath}/.git"
  }

  vcsrepo { $xhprofPath:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/facebook/xhprof.git',
    require  => Exec['delete-xhprof-path-if-not-git-repo']
  }

  file { "${xhprofPath}/xhprof_html":
    ensure  => directory,
    mode    => 0775,
    require => Vcsrepo[$xhprofPath]
  }

  composer::exec { 'xhprof-composer-run':
    cmd     => 'install',
    cwd     => $xhprofPath,
    require => [
      Class['composer'],
      File["${xhprofPath}/xhprof_html"]
    ]
  }
}

## Begin MySQL manifest

if is_hash($mysql_values) and $mysql_values['install'] == 1 and $mysql_values['root_password'] {
  class { 'mysql::server':
    root_password => $mysql_values['root_password'],
  }

  if is_hash($mysql_values['databases']) and count($mysql_values['databases']) > 0 {
    create_resources(mysql_db, $mysql_values['databases'])
  }

  if is_hash($php_values) {
    if $::osfamily == 'redhat' and $php_values['version'] == '53' and ! defined(Php::Module['mysql']) {
      php::module { 'mysql': }
    } elsif ! defined(Php::Module['mysqlnd']) {
      php::module { 'mysqlnd': }
    }
  }
}

define mysql_db (
  $user,
  $password,
  $host,
  $grant    = [],
  $sql_file = false
) {
  if $name == '' or $password == '' or $host == '' {
    fail( 'MySQL DB requires that name, password and host be set. Please check your settings!' )
  }

  mysql::db { $name:
    user     => $user,
    password => $password,
    host     => $host,
    grant    => $grant,
    sql      => $sql_file,
  }
}

## Begin PostgreSQL manifest

if is_hash($postgresql_values) and $postgresql_values['install'] == 1 {
  if $postgresql_values['root_password'] {
    group { $postgresql_values['user_group']:
        ensure => present
    }

    class { 'postgresql::server':
      postgres_password => $postgresql_values['root_password'],
      require           => Group[$postgresql_values['user_group']]
    }

    if is_hash($postgresql_values['databases']) and count($postgresql_values['databases']) > 0 {
      create_resources(postgresql_db, $postgresql_values['databases'])
    }

    if is_hash($php_values) and ! defined(Php::Module['pgsql']) {
      php::module { 'pgsql': }
    }
  }
}

define postgresql_db (
  $user,
  $password,
  $grant,
  $sql_file = false
) {
  if $name == '' or $user == '' or $password == '' or $grant == '' {
    fail( 'PostgreSQL DB requires that name, user, password and grant be set. Please check your settings!' )
  }

  postgresql::server::db { $name:
    user     => $user,
    password => $password,
    grant    => $grant
  }

  if $sql_file {
    $table = "${name}.*"

    exec{ "${name}-import":
      command     => "psql ${name} < ${sql_file}",
      logoutput   => true,
      refreshonly => $refresh,
      require     => Postgresql::Server::Db[$name],
      onlyif      => "test -f ${sql_file}"
    }
  }
}

# Begin PHPMyAdmin

if is_hash($mysql_values) and is_hash($php_values) and $mysql_values['phpmyadmin'] == 1 {
  if $::osfamily == 'debian' {
    if $::operatingsystem == 'ubuntu' {
      apt::key { '80E7349A06ED541C': }
      apt::ppa { 'ppa:nijel/phpmyadmin': require => Apt::Key['80E7349A06ED541C'] }
    }

    $phpMyAdmin_package = 'phpmyadmin'
    $phpMyAdmin_folder = 'phpmyadmin'
  } elsif $::osfamily == 'redhat' {
    $phpMyAdmin_package = 'phpMyAdmin.noarch'
    $phpMyAdmin_folder = 'phpMyAdmin'
  }

  if ! defined(Package[$phpMyAdmin_package]) {
    package { $phpMyAdmin_package:
      require => Class['mysql::server']
    }
  }

  include puphpet::params

  if is_hash($apache_values) and $apache_values['install'] == 1 {
    $mysql_webroot_location = $puphpet::params::apache_webroot_location
  } elsif is_hash($nginx_values) and $nginx_values['install'] == 1 {
    $mysql_webroot_location = $puphpet::params::nginx_webroot_location

    mysql_nginx_default_conf { 'override_default_conf':
      webroot => $mysql_webroot_location
    }
  }

  file { "${mysql_webroot_location}/phpmyadmin":
    target  => "/usr/share/${phpMyAdmin_folder}",
    ensure  => link,
    replace => 'no',
    require => [
      Package[$phpMyAdmin_package],
      File[$mysql_webroot_location]
    ]
  }
}

define mysql_nginx_default_conf (
  $webroot
) {
  if $php5_fpm_sock == undef {
    $php5_fpm_sock = '/var/run/php5-fpm.sock'
  }

  if $fastcgi_pass == undef {
    $fastcgi_pass = $php_values['version'] ? {
      undef   => null,
      '53'    => '127.0.0.1:9000',
      default => "unix:${php5_fpm_sock}"
    }
  }

  class { 'puphpet::nginx':
    fastcgi_pass => $fastcgi_pass,
    notify       => Class['nginx::service'],
  }
}

# Begin Mailcatcher

if is_hash($php_values) and $php_values['mailcatcher'] == 1 {
  puphpet::ini { 'sendmail_path':
    entry       => "CUSTOM/sendmail_path",
    value       => '/usr/bin/env catchmail',
    php_version => $php_values['version'],
    webserver   => $php_webserver_service
  }

  class { 'mailcatcher':
    service  => $php_webserver_service,
    start    => true,
  }
}

# Begin Node

if is_hash($node_values) and $node_values['install'] == 1 {
  class { 'nodejs':
    manage_repo => true,
    #https://github.com/puppetlabs/puppetlabs-nodejs/issues/48
    #version     => '0.10.19-1chl1~precise1'
  }

  # get rid of old npm and install new one
  exec { 'install-npm':
    command     => '/usr/bin/curl https://npmjs.org/install.sh | /bin/sh', # | sudo clean=yes /bin/sh
    environment => 'clean=yes',
    require     => [
      Class['nodejs'],
      Package['curl'],
    ],
  }

  $node_values['npm'].each |$key| {
    add_node_package { $key:
      require  => [
        Class['nodejs'],
        Exec['install-npm'],
      ]
    }
  }

  $node_values['gems'].each |$key| {
    if ! defined(Package[$name]) {
      package { $key:
        ensure   => 'installed',
        provider => 'gem',
        require  => [
          Class['nodejs'],
          Exec['install-npm'],
        ]
      }
    }
  }
}

define add_node_package (
  $ensure       = present,
  $version      = '',
  $source       = '',
  $install_opt  = '',
  $remove_opt   = '',
  $path         = '',
  $local        = false,
){
  validate_bool($local)

  if $local {
    nodejs::npm { "$path:$name":
      ensure      => $ensure,
      version     => $version,
      source      => $source,
      install_opt => $install_opt,
      remove_opt  => $remove_opt,
    }
  } else {
    if ! defined(Package[$name]) {
      package { $name:
        ensure   => $ensure,
        provider => 'npm',
      }
    }
  }
}

## Begin NGrok

if is_hash($ngrok_values) and $ngrok_values['install'] == 1 {
  class { 'ngrok':
    start     => true,
    port      => $ngrok_values['port'],
    subdomain => $ngrok_values['subdomain'],
    httpauth  => $ngrok_values['httpauth'],
    proto     => $ngrok_values['proto'],
    client    => $ngrok_values['client'],
  }
}

## Begin Application

if is_hash($application_values) and $application_values['install'] != undef and $application_values['install'] == 1 {
  $application_values['sites'].each |$key, $value| {
    if $value['install'] != undef and $value['install'] == 1 {
      if is_hash($apache_values) and $apache_values['install'] == 1 and $apache_values['vhosts'][$key] != undef {
        $application_directory = $apache_values['vhosts'][$key]['docroot']
      } elsif is_hash($nginx_values) and $nginx_values['install'] == 1 and $nginx_values['vhosts'][$key] != undef {
        $application_directory = $nginx_values['vhosts'][$key]['www_root']
      } else {
        $application_directory = undef
      }

      if $application_directory != undef {
        case $value['provider'] {
          'git': {
            add_application_repo{ $key:
              source        => $value['source'],
              type          => 'git',
              args          => $value['args'],
              pre_process   => $value['pre_process'],
              post_process  => $value['post_process'],
              directory     => $application_directory,
            }
          }
          'composer': {
            add_application_composer{ $key:
              source        => $value['source'],
              args          => $value['args'],
              pre_process   => $value['pre_process'],
              post_process  => $value['post_process'],
              directory     => $application_directory,
            }
          }
        }
      }
    }
  }
}

define add_application_composer (
  $source       = '',
  $args         = '',
  $directory    = '',
  $pre_process  = undef,
  $post_process = undef,
){
  # anchor resource provides a consistent dependency for prereq.
  anchor { 'application_composer::begin': }
  anchor { 'application_composer::end': }

  if $pre_process != undef and count($pre_process) > 0 {
    $pre_process.each |$key| {
      exec { 'app-pre-commands-${key}': 
        command   => $key,
        cwd       => $directory,
        before    => Anchor['application_composer::begin']
      }
    }
  }

  exec { 'app-delete-if-doesnt-exist':
    command => "rm -rf ${directory}",
    onlyif => "test ! -f ${directory}/composer.json",
  }

  if $php_values['composer'] == 0 {
    add_composer { "composer":
      require => Exec['app-delete-if-doesnt-exist']
    }
  }

  # Only one of prefer_source or prefer_dist can be true
  if ($args['prefer_dist'] != undef and $args['prefer_dist'] == true) {
    $prefer_source = false
    $prefer_dist   = true
  } else {
    $prefer_source = true
    $prefer_dist   = false
  }

  #$packages          = $args['packages'] != undef ? $args['packages'] : ''
  #$custom_installers = $args['custom_installers'] != undef ? $args['dev'] : false
  #$scripts           = $args['scripts'] != undef ? $args['scripts'] : false
  #$optimize          = $args['optimize'] != undef ? $args['optimize'] : false
  #$dev               = $args['dev'] != undef ? $args['dev'] : false

  #composer::exec { $source:
  #  cmd                => 'install',
  #  cwd                => $directory,
  #  packages           => $packages,
  #  prefer_source      => $prefer_source,
  #  prefer_dist        => $prefer_dist,
  #  custom_installers  => $custom_installers,
  #  scripts            => $scripts,
  #  optimize           => $optimize,
  #  dev                => $dev,
  #  interaction        => true,
  #  before             => Anchor['application::end'],
  #  require            => [
  #    Anchor['application::begin'],
  #    Exec['app-delete-if-doesnt-exist'],
  #    Class['composer'],
  #  ],
  #}

  if $args['version'] != undef {
    $version = $args['version']
  } else {
    $version = undef
  }

  if $args['stability'] != undef {
    $stability = $args['stability']
  } else {
    $stability = 'dev'
  }

  if $args['keep_vcs'] != undef {
    $keep_vcs = $args['keep_vcs']
  } else {
    $keep_vcs = false
  }

  if $args['dev'] != undef {
    $dev = $args['dev']
  } else {
    $dev = false
  }

  if $args['repo'] != undef {
    $repo = $args['repo']
  } else {
    $repo = undef
  }

  composer::project { 'install-application-composer':
    project_name      => $source,
    target_dir        => $directory,
    version           => $version,
    prefer_source     => $prefer_source,
    prefer_dist       => $prefer_dist,
    stability         => $stability,
    keep_vcs          => $keep_vcs,
    dev               => $dev,
    repository_url    => $repo,
    interaction       => true,
    before            => Anchor['application_composer::end'],
    require           => [
      Anchor['application_composer::begin'],
      Exec['app-delete-if-doesnt-exist'],
      Class['composer'],
    ],
  }

  if $post_process != undef and count($post_process) > 0 {
    $post_process.each |$key| {
      exec { 'app-post-commands-${key}': 
        command   => $key,
        cwd       => $directory,
        require   => Anchor['application_composer::end']
      }
    }
  }
}

define add_application_repo (
  $source       = '',
  $type         = '',
  $args         = '',
  $directory    = '',
  $pre_process  = undef,
  $post_process = undef,
){

  # anchor resource provides a consistent dependency for prereq.
  anchor { 'application_repo::begin': }
  anchor { 'application_repo::end': }

  if $pre_process != undef and count($pre_process) > 0 {
    $pre_process.each |$key| {
      exec { 'app-pre-commands-${key}': 
        command   => $key,
        cwd       => $directory,
        before    => Anchor['application_repo::begin']
      }
    }
  }

  exec { 'app-delete-if-doesnt-exist':
    command => "rm -rf ${directory}",
    onlyif => "test ! -d ${directory}/.git",
  }

  if $args['revision'] != undef {
    $revision = $args['revision']
  } else {
    $revision = undef
  }

  vcsrepo { $directory:
    ensure   => present,
    provider => $type,
    source   => $source,
    revision => $revision,
    before   => Anchor['application_repo::end'],
    require  => [
      Anchor['application_repo::begin'],
      Exec['app-delete-if-doesnt-exist'],
    ],
  }

  if $post_process != undef and count($post_process) > 0 {
    $post_process.each |$key| {
      exec { 'app-post-commands-${key}': 
        command   => $key,
        cwd       => $directory,
        require   => Anchor['application_repo::end']
      }
    }
  }
}

## Begin final manifest

notify {"finished":
  message => "I'm Finished"
} 

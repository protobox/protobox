def build_playbook(yaml, protobox_dir)
  protobox_playbook = protobox_dir + '/playbook'

  out = []

  play = {}
  play['name'] = 'Core'
  play['hosts'] = 'all'
  #play['sudo'] = true
  #play['sudo_user'] = 'root'
  play['vars_files'] = ['{{ protobox_config }}']
  
  entries = []

  # Common
  entries << { "role" => "common" }

  # Server
  if !yaml['server'].nil?
    entries << { "role" => "server", "when" => "server is defined" }
  end

  # Database - mysql
  if !yaml['mysql'].nil? and yaml['mysql']['install'].to_i == 1
    entries << { "role" => "mysql", "when" => "mysql is defined and mysql.install == 1" }
  end

  # Database - mariadb
  if !yaml['mariadb'].nil? and yaml['mariadb']['install'].to_i == 1
    entries << { "role" => "mariadb", "when" => "mariadb is defined and mariadb.install == 1" }
  end

  # Database - postgres
  #if !yaml['postgres'].nil? and yaml['postgres']['install'].to_i == 1
  #  entries << { "role" => "postgres", "when" => "postgres is defined and postgres.install == 1" }
  #end

  # Database - mongodb
  #if !yaml['mongodb'].nil? and yaml['mongodb']['install'].to_i == 1
  #  entries << { "role" => "mongodb", "when" => "mongodb is defined and mongodb.install == 1" }
  #end

  # Database - redis
  #if !yaml['redis'].nil? and yaml['redis']['install'].to_i == 1
  #  entries << { "role" => "redis", "when" => "redis is defined and redis.install == 1" }
  #end

  # Search - solr
  if !yaml['solr'].nil? and yaml['solr']['install'].to_i == 1
    entries << { "role" => "solr", "when" => "solr is defined and solr.install == 1" }
  end

  # Search - elasticsearch
  if !yaml['elasticsearch'].nil? and yaml['elasticsearch']['install'].to_i == 1
    entries << { "role" => "elasticsearch", "when" => "elasticsearch is defined and elasticsearch.install == 1" }
  end

  # Languages - python
  if !yaml['python'].nil? and yaml['python']['install'].to_i == 1
    entries << { "role" => "python", "when" => "python is defined and python.install == 1" }
  end

  # Languages - php
  if !yaml['php'].nil? and yaml['php']['install'].to_i == 1
    entries << { "role" => "php", "when" => "php is defined and php.install == 1" }
  end

  # Languages - ruby
  if !yaml['ruby'].nil? and yaml['ruby']['install'].to_i == 1
    entries << { "role" => "ruby", "when" => "ruby is defined and ruby.install == 1" }
  end

  # Languages - node
  if !yaml['node'].nil? and yaml['node']['install'].to_i == 1
    entries << { "role" => "node", "when" => "node is defined and node.install == 1" }
  end

  # Web server - apache
  if !yaml['apache'].nil? and yaml['apache']['install'].to_i == 1
    entries << { "role" => "apache", "when" => "apache is defined and apache.install == 1" }
  end

  # Web server - nginx
  if !yaml['nginx'].nil? and yaml['nginx']['install'].to_i == 1
    entries << { "role" => "nginx", "when" => "nginx is defined and nginx.install == 1" }
  end

  # Web server - hhvm
  if !yaml['hhvm'].nil? and yaml['hhvm']['install'].to_i == 1
    entries << { "role" => "hhvm", "when" => "hhvm is defined and hhvm.install == 1" }
  end

  # Web extras - phalcon
  if !yaml['phalcon'].nil? and yaml['phalcon']['install'].to_i == 1
    entries << { "role" => "phalcon", "when" => "phalcon is defined and phalcon.install == 1" }
  end

  # Web extras - varnish
  if !yaml['varnish'].nil? and yaml['varnish']['install'].to_i == 1
    entries << { "role" => "varnish", "when" => "varnish is defined and varnish.install == 1" }
  end

  # Queues / Messaging - beanstalkd
  #if !yaml['beanstalkd'].nil? and yaml['beanstalkd']['install'].to_i == 1
  #  entries << { "role" => "beanstalkd", "when" => "beanstalkd is defined and beanstalkd.install == 1" }
  #end

  # Queues / Messaging - rabbitmq
  if !yaml['rabbitmq'].nil? and yaml['rabbitmq']['install'].to_i == 1
    entries << { "role" => "rabbitmq", "when" => "rabbitmq is defined and rabbitmq.install == 1" }
  end

  # Tools - newrelic
  if !yaml['newrelic'].nil? and yaml['newrelic']['install'].to_i == 1
    entries << { "role" => "newrelic", "when" => "newrelic is defined and newrelic.install == 1" }
  end

  # Tools - ngrok
  if !yaml['ngrok'].nil? and yaml['ngrok']['install'].to_i == 1
    entries << { "role" => "ngrok", "when" => "ngrok is defined and ngrok.install == 1" }
  end

  #
  # Applications
  #
  if !yaml['applications'].nil? and yaml['applications']['install'].to_i == 1

    # App - repository
    if !yaml['applications']['repository'].nil?
      entries << { "role" => "repository", "dir" => "applications/repository", "when" => "applications.repository is defined" }
    end

    # App - lemonstand
    if !yaml['applications']['lemonstand'].nil?
      entries << { "role" => "lemonstand", "dir" => "applications/lemonstand", "when" => "applications.lemonstand is defined" }
    end

    # App - wordpress
    if !yaml['applications']['wordpress'].nil?
      entries << { "role" => "wordpress", "dir" => "applications/wordpress", "when" => "applications.wordpress is defined" }
    end

    # App - laravel
    if !yaml['applications']['laravel'].nil?
      entries << { "role" => "laravel", "dir" => "applications/laravel", "when" => "applications.laravel is defined" }
    end

    # App - drupal
    if !yaml['applications']['drupal'].nil?
      entries << { "role" => "drupal", "dir" => "applications/drupal", "when" => "applications.drupal is defined" }
    end

    # App - symfony
    if !yaml['applications']['symfony'].nil?
      entries << { "role" => "symfony", "dir" => "applications/symfony", "when" => "applications.symfony is defined" }
    end

    # App - sylius
    if !yaml['applications']['sylius'].nil?
      entries << { "role" => "sylius", "dir" => "applications/sylius", "when" => "applications.sylius is defined" }
    end

    # App - pyrocms
    if !yaml['applications']['pyrocms'].nil?
      entries << { "role" => "pyrocms", "dir" => "applications/pyrocms", "when" => "applications.pyrocms is defined" }
    end

  end

  play['roles'] = entries

  out << play

  # Dump out the contents
  File.open(protobox_playbook, 'w') do |file|
    YAML::dump(out, file)
  end

  return true
end
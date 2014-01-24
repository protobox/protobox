# Protobox #

Protobox is a layer on top of [vagrant](http://vagrantup.com) and a [web GUI](http://getprotobox.com/about) to setup virtual machines for web development. A single [YAML document](https://github.com/protobox/protobox/blob/master/data/config/common.yml-dist) controls everything that is installed on the virtual machine. You can install [popular languages](#languages), [software](#modules), and even [popular web applications](#applications) or your [own private GIT repositories](#applications) with a simple on/off toggle in YAML. You can read more about why this was developed in our [about document](https://github.com/protobox/protobox-docs/blob/master/about.md) or on our website at [getprotobox.com/about](http://getprotobox.com/about). 

## Installation ##

Installation - OSX, *nix

	ruby -e "$(curl -fsSL https://raw.github.com/protobox/protobox/master/ansible/shell/bootstrap)"

Alternatively, you can install it via git manually.

    git clone git@github.com:protobox/protobox.git protobox
    cd protobox && cp data/config/common.yml-dist data/config/common.yml

Make sure you add an entry to your `/etc/hosts` for any virtualhosts in your `data/config/common.yml` file:

	192.168.5.10    protobox.dev www.protobox.dev

Then run `vagrant up` and pull up `http://protobox.dev` in your browser to see if it is setup correctly.

## Configuration ##

The protobox configuration file is found at `data/config/common.yml`. You can easily install new services by setting `install: 1` under any of the software in the configuration file. 

## Functionality ##

Protobox has built in support for the following functionality:

- **Ansible**: Protobox is built using [ansible](http://www.ansibleworks.com/). It's simplicity, yaml format, and agent operation make for a very powerful combination. [Why Ansible?](http://www.ansibleworks.com/why-ansible/).
- **Application Installing**: Set the path to a git repo (public or private) or a composer project and upon vagrant up it will be installed for you. 
- **User Preferences**: Upon boot up your dot files in data/dot will be copied to the virtual machine.
- **SSH Keys**: Place your ssh keys in the data/ssh and reference them from the configuration file to be copied to the virtual machine to easily access any remote servers or github. 
- **SQL Import**: You can add any sql files in data/sql and reference them in the configuration file to be imported upon the bootup of the virtual machine. 
- **Mailcatching**: The mailcatcher package can catch any mail leaving the system for debugging and testing. 
- **Vast Module Selection**: Protobox comes bundled with 15+ of the most common modules that PHP developer use everyday.

## Modules ##

Protobox has built in support for the following modules:

#### OS

- [Ubuntu](http://www.ubuntu.com/server) 10.04, 12.04, 13.10
- [Any Distro](http://www.vagrantbox.es/)

#### Web Server

- [Apache](http://httpd.apache.org/)
- [Nginx](http://wiki.nginx.org/Main)
- [Varnish](https://www.varnish-cache.org/)

#### Languages

**PHP**

- [PHP](http://php.net) 5.3, 5.4, 5.5
- [HHVM - HipHop Virtual Machine](http://www.hiphop-php.com/)
- [Phalcon](http://phalconphp.com/)
- [Composer](http://getcomposer.org/)
- [XDebug](http://xdebug.org/)
- [Xhprof](http://pecl.php.net/package/xhprof)
- [Mailcatcher](http://mailcatcher.me/)

#### Node

- [Node](http://nodejs.org/)
- [Bower](http://bower.io/)
- [Grunt](http://gruntjs.com/)
- Any [Node Modules](https://npmjs.org/)

#### Data Store

- [MySQL](http://www.mysql.com/)
- [MariaDB](https://mariadb.org/)
- [PostgreSQL](http://www.postgresql.org/)
- [Mongodb](http://www.mongodb.org/)
- [Riak](http://basho.com/riak/)
- [Redis](http://redis.io/)
- [Apache Solr](http://lucene.apache.org/solr/)
- [Elasticsearch](http://www.elasticsearch.org/)

#### Queues / Messaging

- [Beanstalkd](http://kr.github.io/beanstalkd/)
- [RabbitMQ](http://www.rabbitmq.com/)

#### Monitoring

- [New Relic](http://newrelic.com/)

#### Dev Tools

- [Ngrok](https://ngrok.com/)

## Applications ##

Protobox has built in support for installing any of these applications:

- [Wordpress](http://wordpress.org/)
- [Magento](http://magento.com/) (Coming Soon)
- [Drupal](https://drupal.org/)
- [Laravel](http://laravel.com/)
- [Lemonstand](http://lemonstand.com/)
- [Symfony](http://symfony.com/)
- [Symfony CMF](http://cmf.symfony.com/) (Coming Soon)
- [Sylius](http://sylius.org/)
- [Akeneo](http://www.akeneo.com/) (Coming Soon)
- [Oro CRM](http://www.orocrm.com/) (Coming Soon)
- [Prestashop](http://www.prestashop.com/) (Coming Soon)
- [PyroCMS](https://www.pyrocms.com/)
- Any public / private GIT repository

## Contributing ##

Use [GitHub Issues](https://github.com/protobox/protobox/issues) to file a bug report or new feature request. Please open a issue prior to opening a pull request to make sure it is something we can merge. The roadmap can be determined by looking at issues tagged as `featured request`.

## Help! ##

Use [GitHub Issues](https://github.com/protobox/protobox/issues) or #protobox on irc.freenode.net.

## Credit ##

Protobox was developed by [Patrick Heeney](https://github.com/patrickheeney) and inspired by the [puphpet](https://github.com/puphpet/puphpet) project. A special thanks goes out to our [contributors](https://github.com/protobox/protobox/graphs/contributors) for helping grow this project. Protobox is also made possible by the best orchestration engine in existence: [ansible](http://www.ansibleworks.com/).

## License ##

Protobox is licensed under the [MIT license](http://opensource.org/licenses/mit-license.php).

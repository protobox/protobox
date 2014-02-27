# Protobox #

Protobox is a layer on top of [vagrant](http://vagrantup.com) and a [web GUI](http://getprotobox.com/about) to setup virtual machines for web development. A single [YAML document](https://github.com/protobox/protobox/blob/master/data/config/common.yml-dist) controls everything that is installed on the virtual machine. You can install [popular languages](https://github.com/protobox/protobox-docs/blob/master/modules.md#languages), [software](https://github.com/protobox/protobox-docs/blob/master/modules.md), and even [popular web applications](https://github.com/protobox/protobox-docs/blob/master/applications.md) or your [own private GIT repositories](#applications) with a simple on/off toggle in YAML. You can read more about why this was developed in our [about document](https://github.com/protobox/protobox-docs/blob/master/about.md) or on our website at [getprotobox.com](http://getprotobox.com/docs/about). 

## Installation ##

Installation - OSX, *nix

	ruby -e "$(curl -fsSL https://raw.github.com/protobox/protobox/master/ansible/shell/bootstrap)"

Alternatively, you can install it via git manually.

    git clone git@github.com:protobox/protobox.git protobox
    cd protobox && cp data/config/common.yml-dist data/config/common.yml

Then run `vagrant up` and pull up `http://192.168.5.10/` in your browser to see if it is setup correctly.

## Configuration ##

The protobox configuration file is found at `data/config/common.yml`. You can easily install new services by setting `install: 1` under any of the software in the configuration file. Alternatively you can drag and drop your yml file to make changes with our web gui at [getprotobox.com](http://getprotobox.com). 

## Functionality ##

Protobox has built in support for the following functionality:

- **Vast Module Selection**: Protobox comes bundled with 15+ of the most common modules that PHP developer use everyday.
- **Application Installing**: Set the path to a git repo (public or private) or a composer project and upon vagrant up it will be installed for you. 
- **User Preferences**: Upon boot up your dot files in data/dot will be copied to the virtual machine.
- **SSH Keys**: Place your ssh keys in the data/ssh and reference them from the configuration file to be copied to the virtual machine to easily access any remote servers or github. 
- **SQL Import**: You can add any sql files in data/sql and reference them in the configuration file to be imported upon the bootup of the virtual machine. 
- **Mailcatching**: The mailcatcher package can catch any mail leaving the system for debugging and testing. 
- **Ansible**: Protobox is built using [ansible](http://www.ansibleworks.com/). It's simplicity, yaml format, and agent operation make for a very powerful combination. [Why Ansible?](http://www.ansibleworks.com/why-ansible/).

## Modules ##

Protobox has built in support for any OS, common web servers, and languages. See the full list by reading the [modules document](https://github.com/protobox/protobox-docs/blob/master/modules.md) or on our website at [getprotobox.com](http://getprotobox.com/docs/modules). 

## Applications ##

Protobox has built in support for popular applications. See the full list by reading the [applications document](https://github.com/protobox/protobox-docs/blob/master/applications.md) or on our website at [getprotobox.com](http://getprotobox.com/docs/applications). 

## Contributing ##

Check out our [roadmap](http://getprotobox.com/docs/roadmap) for upcoming features and how to help.

Use [GitHub Issues](https://github.com/protobox/protobox/issues) to file a bug report or new feature request. Please open a issue prior to opening a pull request to make sure it is something we can merge. The roadmap can be determined by looking at issues tagged as `featured request`.

## Help! ##

Use [GitHub Issues](https://github.com/protobox/protobox/issues) or #protobox on irc.freenode.net.

## Credit ##

Protobox was developed by [Patrick Heeney](https://github.com/patrickheeney) and inspired by the [puphpet](https://github.com/puphpet/puphpet) project. A special thanks goes out to our [contributors](https://github.com/protobox/protobox/graphs/contributors) for helping grow this project. Protobox is also made possible by the best orchestration engine in existence: [ansible](http://www.ansibleworks.com/).

## License ##

Protobox is licensed under the [MIT license](http://opensource.org/licenses/mit-license.php).

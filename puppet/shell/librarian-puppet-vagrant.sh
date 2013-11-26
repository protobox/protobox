#!/bin/bash

OS=$(/bin/bash /vagrant/puppet/shell/os-detect.sh ID)
CODENAME=$(/bin/bash /vagrant/puppet/shell/os-detect.sh CODENAME)

# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR=/etc/puppet/
PUPPET_LOC=/etc/puppet/Puppetfile
PUPPET_FILE=/.protobox/puppetfile.build
PUPPET_DATA=/vagrant/data/vagrant/common.yaml

$(which git > /dev/null 2>&1)
FOUND_GIT=$?

if [ "$FOUND_GIT" -ne '0' ] && [ ! -f /.protobox/librarian-puppet-installed ]; then
    $(which apt-get > /dev/null 2>&1)
    FOUND_APT=$?
    $(which yum > /dev/null 2>&1)
    FOUND_YUM=$?

    echo 'Installing git'

    if [ "${FOUND_YUM}" -eq '0' ]; then
        yum -q -y makecache
        yum -q -y install git
    else
        apt-get -q -y install git-core >/dev/null 2>&1
    fi

    echo 'Finished installing git'
fi

if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
    if [[ ! -f /.protobox/librarian-base-packages ]]; then
        echo 'Installing base packages for librarian'
        apt-get install -y build-essential ruby-dev libsqlite3-dev >/dev/null 2>&1
        echo 'Finished installing base packages for librarian'

        touch /.protobox/librarian-base-packages
    fi
fi

if [ "$OS" == 'ubuntu' ]; then
    if [[ ! -f /.protobox/librarian-libgemplugin-ruby ]]; then
        echo 'Updating libgemplugin-ruby (Ubuntu only)'
        apt-get install -y libgemplugin-ruby >/dev/null 2>&1
        echo 'Finished updating libgemplugin-ruby (Ubuntu only)'

        touch /.protobox/librarian-libgemplugin-ruby
    fi

    if [ "$CODENAME" == 'lucid' ] && [ ! -f /.protobox/librarian-rubygems-update ]; then
        echo 'Updating rubygems (Ubuntu Lucid only)'
        echo 'Ignore all "conflicting chdir" errors!'
        gem install rubygems-update >/dev/null 2>&1
        /var/lib/gems/1.8/bin/update_rubygems >/dev/null 2>&1
        echo 'Finished updating rubygems (Ubuntu Lucid only)'

        touch /.protobox/librarian-rubygems-update
    fi
fi

if [[ ! -d "$PUPPET_DIR" ]]; then
    mkdir -p "$PUPPET_DIR"
    echo "Created directory $PUPPET_DIR"
fi

if [[ -f "$PUPPET_FILE" ]]; then
    rm -f "$PUPPET_FILE"
    echo "Deleted existing puppetfile build"
fi

#if [[ ! -f "$PUPPET_DATA" ]]; then
#    echo "File does not exist: $PUPPET_DATA"
#    exit 1
#fi

if [[ ! -f "$PUPPET_FILE" ]] && [[ -f "$PUPPET_DATA" ]]; then
    echo "Building puppetfile from yaml"
    cd /vagrant/puppet/shell/ && ruby build-puppetfile.rb -s "$PUPPET_DATA" > "$PUPPET_FILE"
    echo "Finished building puppetfile"
fi

if [[ ! -f "$PUPPET_LOC" ]]; then
    touch "$PUPPET_LOC"
    echo "Created Puppetfile at $PUPPET_LOC"
fi

if [[ -f "$PUPPET_FILE" ]] && [[ -f "$PUPPET_LOC" ]]; then
    cat "$PUPPET_FILE" >> "$PUPPET_LOC"
    echo "Copied Puppetfile to $PUPPET_LOC"
fi

if [[ ! -f /.protobox/librarian-puppet-installed ]]; then
    echo 'Installing librarian-puppet'
    gem install librarian-puppet >/dev/null 2>&1
    echo 'Finished installing librarian-puppet'

    echo 'Running initial librarian-puppet'
    cd "$PUPPET_DIR" && librarian-puppet install --clean >/dev/null 2>&1
    echo 'Finished running initial librarian-puppet'

    touch /.protobox/librarian-puppet-installed
else
    echo 'Running update librarian-puppet'
    cd "$PUPPET_DIR" && librarian-puppet update >/dev/null 2>&1
    echo 'Finished running update librarian-puppet'
fi

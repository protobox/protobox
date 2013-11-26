#!/bin/bash

OS=$(/bin/bash /vagrant/puppet/shell/os-detect.sh ID)
CODENAME=$(/bin/bash /vagrant/puppet/shell/os-detect.sh CODENAME)

if [[ ! -d /.protobox ]]; then
    mkdir /.protobox
    echo "Created directory /.protobox"
fi

if [[ ! -f /.protobox/initial-setup-repo-update ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running initial-setup apt-get update"
        apt-get update >/dev/null 2>&1
        touch /.protobox/initial-setup-repo-update
        echo "Finished running initial-setup apt-get update"
    elif [[ "$OS" == 'centos' ]]; then
        echo "Running initial-setup yum update"
        yum update -y >/dev/null 2>&1
        echo "Finished running initial-setup yum update"

        echo "Installing basic development tools (CentOS)"
        yum -y groupinstall "Development Tools" >/dev/null 2>&1
        echo "Finished installing basic development tools (CentOS)"
        touch /.protobox/initial-setup-repo-update
    fi
fi

if [[ "$OS" == 'ubuntu' && ("$CODENAME" == 'lucid' || "$CODENAME" == 'precise') && ! -f /.protobox/ubuntu-required-libraries ]]; then
    echo 'Installing basic curl packages (Ubuntu only)'
    apt-get install -y libcurl3 libcurl4-gnutls-dev >/dev/null 2>&1
    echo 'Finished installing basic curl packages (Ubuntu only)'

    touch /.protobox/ubuntu-required-libraries
fi

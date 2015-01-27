#!/bin/bash

OS=$(/bin/bash /vagrant/lib/os-detect.sh ID)
CODENAME=$(/bin/bash /vagrant/lib/os-detect.sh CODENAME)
ANSIBLE_VERSION=`cat /vagrant/.protobox/ansible_version`
ANSIBLE_ARGS=`cat /vagrant/.protobox/ansible_args`

warn() {
    printf >&2 "$SCRIPTNAME: $*\n"
}

iscmd() {
    command -v >&- "$@"
}

# start protobox

#if [[ ! -d /.protobox ]]; then
#    mkdir /.protobox
#    echo "Created directory /.protobox"
#fi

# 
# Install python setup tools
# 
if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
    echo "Running apt-get install python-setuptools"
    apt-get install python-setuptools >/dev/null 2>&1
    echo "Finished running apt-get install python-setuptools"
elif [[ "$OS" == 'centos' ]]; then
    echo "TODO - centos"
    #yum install install python-pip python-devel
fi

#
# Install pip
#
if ! iscmd "pip"; then
    echo "Running easy_install pip"
    easy_install pip >/dev/null 2>&1
    echo "Finished running easy_install pip"
else
    echo "pip already installed"
fi

#
# Install ansible
#
if ! iscmd "ansible"; then
    if [ "$ANSIBLE_VERSION" != 'latest' ]; then
        if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
            echo "Running pip install ansible==$ANSIBLE_VERSION"
            pip install ansible==$ANSIBLE_VERSION >/dev/null 2>&1
            echo "Finished pip install ansible==$ANSIBLE_VERSION"
        elif [ "$OS" == 'centos' ]; then
            echo "TODO - centos ansible"
            #pip install ansible==$ANSIBLE_VERSION
        fi
    else
        if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
            echo "Running pip install ansible"
            pip install ansible >/dev/null 2>&1
            echo "Finished pip install ansible"
        elif [ "$OS" == 'centos' ]; then
            echo "TODO - centos ansible"
            #pip install ansible
        fi
    fi
else
    echo "ansible already installed"
fi

#
# Configure ansible
#

if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
    echo "Installing ansible config"

    # Setup directory
    if [ ! -d "/etc/ansible" ]; then
        mkdir -p /etc/ansible
    fi

    # Setup hosts
    if [ ! -f "/etc/ansible/hosts" ]; then
        touch /etc/ansible/hosts
        #echo "localhost" > /etc/ansible/hosts
        #echo "127.0.0.1" > /etc/ansible/hosts
        echo "localhost ansible_connection=local" > /etc/ansible/hosts
    fi

    # Setup config
    #if [ ! -f "/etc/ansible/ansible.cfg" ]; then
        cp /vagrant/lib/ansible.cfg /etc/ansible/ansible.cfg
    #fi

    echo "Finished installing ansible config"
elif [ "$OS" == 'centos' ]; then
    echo "TODO - centos ansible setup"
fi

# Has galaxy file
if [ -f "/vagrant/.protobox/ansible_requirements.yml" ]; then
    echo "Installing ansible galaxy roles"
    # --ignore-errors
    ansible-galaxy install --force -r /vagrant/.protobox/ansible_requirements.yml
fi

# Run ansible playbook
echo "Running ansible-playbook $ANSIBLE_ARGS"
sh -c "ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false PYTHONUNBUFFERED=1 ansible-playbook $ANSIBLE_ARGS"
echo "Finished ansible-playbook"


<<COMMENT1
if [[ ! -f /.protobox/initial-update ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running initial-setup apt-get update"
        apt-get update -y >/dev/null 2>&1
        echo "Finished running initial-setup apt-get update"

        touch /.protobox/initial-update
    elif [[ "$OS" == 'centos' ]]; then
        echo "Running initial-setup yum update"
        yum update -y >/dev/null 2>&1
        echo "Finished running initial-setup yum update"

        echo "Installing basic development tools (CentOS)"
        yum -y groupinstall "Development Tools" >/dev/null 2>&1
        echo "Finished installing basic development tools (CentOS)"

        touch /.protobox/initial-update
    fi
fi
COMMENT1

<<COMMENT2
if [[ "$OS" == 'ubuntu' && ("$CODENAME" == 'lucid' || "$CODENAME" == 'precise') && ! -f /.protobox/ubuntu-required-libraries ]]; then
    echo 'Installing basic curl packages (Ubuntu only)'
    apt-get install -y libcurl3 libcurl4-gnutls-dev >/dev/null 2>&1
    echo 'Finished installing basic curl packages (Ubuntu only)'

    touch /.protobox/ubuntu-required-libraries
fi
COMMENT2

<<COMMENT3
if [[ ! -f /.protobox/python-software-properties ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running python-software-properties"
        apt-get -y install python-software-properties >/dev/null 2>&1
        echo "Finished python-software-properties"

        touch /.protobox/python-software-properties
    elif [ "$OS" == 'centos' ]; then


        touch /.protobox/python-software-properties
    fi
fi
COMMENT3

<<COMMENT4
if [[ ! -f /.protobox/install-pip ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Installing python-pip"
        apt-get -y install python-pip python-dev >/dev/null 2>&1
        echo "Finished python-pip"

        touch /.protobox/install-pip
    elif [ "$OS" == 'centos' ]; then
        #yum install install python-pip python-devel

        touch /.protobox/install-pip
    fi
fi
COMMENT4

<<COMMENT5
if [[ ! -f /.protobox/install-ansible ]]; then
    if [ "$ANSIBLE_VERSION" != 'latest' ]; then
        if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
            echo "Running pip install ansible==$ANSIBLE_VERSION"
            pip install ansible==$ANSIBLE_VERSION >/dev/null 2>&1
            echo "Finished pip install ansible==$ANSIBLE_VERSION"

            touch /.protobox/install-ansible
        elif [ "$OS" == 'centos' ]; then
            #pip install ansible==$ANSIBLE_VERSION

            touch /.protobox/install-ansible
        fi
    else
        if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
            echo "Running pip install ansible"
            pip install ansible >/dev/null 2>&1
            echo "Finished pip install ansible"

            touch /.protobox/install-ansible
        elif [ "$OS" == 'centos' ]; then
            #pip install ansible

            touch /.protobox/install-ansible
        fi
    fi
fi
COMMENT5

<<COMMENT6
if [[ ! -f /.protobox/install-ansible-hosts ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Installing ansible hosts"
        mkdir -p /etc/ansible

        # Setup hosts
        touch /etc/ansible/hosts
        #echo "localhost" > /etc/ansible/hosts
        #echo "127.0.0.1" > /etc/ansible/hosts
        echo "localhost ansible_connection=local" > /etc/ansible/hosts

        # Setup config
        cp /vagrant/lib/ansible/ansible.cfg /etc/ansible/ansible.cfg

        touch /.protobox/install-ansible-hosts
    elif [ "$OS" == 'centos' ]; then

        touch /.protobox/install-ansible-hosts
    fi
fi

# Run ansible playbook
echo "Running ansible-playbook $PARAMS"
sh -c "ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false PYTHONUNBUFFERED=1 ansible-playbook $PARAMS"
echo "Finished ansible-playbook"
COMMENT6


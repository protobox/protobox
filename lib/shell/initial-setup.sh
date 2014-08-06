#!/bin/bash

OS=$(/bin/bash /vagrant/lib/shell/os-detect.sh ID)
CODENAME=$(/bin/bash /vagrant/lib/shell/os-detect.sh CODENAME)

PUPPET_LOCATION=( $( /bin/cat /vagrant/.protobox/config ) )
PUPPET_DATA="/vagrant/$PUPPET_LOCATION"
PROTOBOX_LOGO=/vagrant/lib/shell/logo.txt
ANSIBLE_VERSION=( $( /bin/cat /vagrant/.protobox/ansible_version ) )

# process arguments
while getopts ":a:" opt; do
  case $opt in
    a)
      PARAMS="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ "$PARAMS" == "" ]]; then
    echo "ERROR: Options -a require arguments." >&2
    exit 1
fi

# start protobox

if [[ ! -d /.protobox ]]; then
    mkdir /.protobox
    echo "Created directory /.protobox"
fi

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

if [[ "$OS" == 'ubuntu' && ("$CODENAME" == 'lucid' || "$CODENAME" == 'precise') && ! -f /.protobox/ubuntu-required-libraries ]]; then
    echo 'Installing basic curl packages (Ubuntu only)'
    apt-get install -y libcurl3 libcurl4-gnutls-dev >/dev/null 2>&1
    echo 'Finished installing basic curl packages (Ubuntu only)'

    touch /.protobox/ubuntu-required-libraries
fi

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

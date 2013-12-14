#!/bin/bash

OS=$(/bin/bash /vagrant/ansible/shell/os-detect.sh ID)
CODENAME=$(/bin/bash /vagrant/ansible/shell/os-detect.sh CODENAME)

PUPPET_LOCATION=( $( /bin/cat /vagrant/.protobox/config ) )
PUPPET_DATA="/vagrant/$PUPPET_LOCATION"
PROTOBOX_LOGO=/vagrant/ansible/shell/logo.txt

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

if [[ ! -f /.protobox/add-ansible-repo ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running add-apt-repository ansible"
        add-apt-repository -y ppa:rquillo/ansible >/dev/null 2>&1
        echo "Finished add-apt-repository ansible"

        echo "Running apt-get update"
        apt-get update -y >/dev/null 2>&1
        echo "Finished running apt-get update"

        touch /.protobox/add-ansible-repo
    elif [ "$OS" == 'centos' ]; then

        touch /.protobox/add-ansible-repo
    fi
fi

if [[ ! -f /.protobox/install-ansible ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Running apt-get install ansible"
        apt-get -y install ansible >/dev/null 2>&1
        echo "Finished apt-get install ansible"

        touch /.protobox/install-ansible
    elif [ "$OS" == 'centos' ]; then
        echo "Running yum install ansible"
        sudo yum install ansible >/dev/null 2>&1
        echo "Finished yum install ansible"

        touch /.protobox/install-ansible
    fi
fi

if [[ ! -f /.protobox/install-ansible-hosts ]]; then
    if [ "$OS" == 'debian' ] || [ "$OS" == 'ubuntu' ]; then
        echo "Installing ansible hosts"
        mkdir -p /etc/ansible
        touch /etc/ansible/hosts
        #echo "localhost" > /etc/ansible/hosts
        #echo "127.0.0.1" > /etc/ansible/hosts
        echo "localhost ansible_connection=local" > /etc/ansible/hosts

        touch /.protobox/install-ansible-hosts
    elif [ "$OS" == 'centos' ]; then

        touch /.protobox/install-ansible-hosts
    fi
fi

if [[ ! -f /.protobox/run-ansible ]]; then
    echo "Running ansible-playbook $PARAMS"
    sh -c "sudo ansible-playbook $PARAMS"
    echo "Finished ansible-playbook"

    touch /.protobox/run-ansible
fi

if [[ ! -f /.protobox/finish-protobox ]]; then
    echo "Finishing protobox"
    ruby /vagrant/ansible/shell/finish-setup.rb -s "$PUPPET_DATA" -l "$PROTOBOX_LOGO"

    touch /.protobox/finish-protobox
fi

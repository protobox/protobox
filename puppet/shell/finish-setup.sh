#!/bin/bash

OS=$(/bin/bash /vagrant/puppet/shell/os-detect.sh ID)
CODENAME=$(/bin/bash /vagrant/puppet/shell/os-detect.sh CODENAME)

PUPPET_DATA=/vagrant/data/vagrant/common.yaml
PROTOBOX_LOGO=/vagrant/puppet/shell/logo.txt

cd /vagrant/puppet/shell/ && ruby finish-setup.rb -s "$PUPPET_DATA" -l "$PROTOBOX_LOGO"

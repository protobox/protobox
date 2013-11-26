# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

dir = Dir.pwd
vagrant_dir = File.expand_path(File.dirname(__FILE__))
vagrant_file = 'data/vagrant/common.yaml'

if !File.file?(vagrant_file)
  puts "Data file is missing: #{vagrant_file}\n"
  exit
end

settings = YAML.load_file(vagrant_file)

Vagrant.configure("2") do |config|

  # Store the current version of Vagrant for use in conditionals when dealing
  # with possible backward compatible issues.
  vagrant_version = Vagrant::VERSION.sub(/^v/, '')

  vagrant_vm = 'vagrantfile-local'

  # Default Box
  config.vm.box = settings[vagrant_vm]['vm']['box']
  config.vm.box_url = settings[vagrant_vm]['vm']['box_url']

  if !settings[vagrant_vm]['vm']['hostname'].nil?
    config.vm.hostname = settings[vagrant_vm]['vm']['hostname']
  end
 
  # Ports and IP Address
  if !settings[vagrant_vm]['vm']['usable_port_range'].nil?
    ends = settings[vagrant_vm]['vm']['usable_port_range'].to_s.split('..').map{|d| Integer(d)}
    config.vm.usable_port_range = (ends[0]..ends[1])
  end

  config.vm.network :private_network, ip: settings[vagrant_vm]['vm']['network']['private_network'].to_s

  settings[vagrant_vm]['vm']['network']['forwarded_port'].each do |item, port|
    if !port['guest'].nil? and 
       !port['host'].nil? and 
       !port['guest'].empty? and 
       !port['host'].empty?
      config.vm.network :forwarded_port, guest: Integer(port['guest']), host: Integer(port['host'])
    end
  end

  # Synced Folders
  settings[vagrant_vm]['vm']['synced_folder'].each do |item, folder|
    if !folder['source'].nil? and !folder['target'].nil?
      id = !folder['id'].nil? ? folder['id'] : ''
      nfs = !folder['nfs'].nil? ? folder['nfs'] : false
      dis = !folder['disabled'].nil? ? folder['disabled'] : false
      own = !folder['owner'].nil? ? folder['owner'] : ''
      grp = !folder['group'].nil? ? folder['group'] : ''
      opt = !folder['mount_options'].nil? ? folder['mount_options'] : Array.new

      config.vm.synced_folder folder['source'], folder['target'], id: id, disabled: dis, owner: own, group: grp, :nfs => nfs, :mount_options => opt
    end
  end

  # Virtual Box Configuration
  settings[vagrant_vm]['vm']['provider'].each do |prov, options|
    config.vm.provider prov.to_sym do |params|
      options.each do |type, values|
        values.each do |key, value|
          params.customize [type, :id, "--#{key}", value]
        end
      end
    end
  end

  # Time Zone
  #config.vm.provision :shell, :inline => "echo \"America/Chicago\" | sudo tee /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata"

  # Shell Provisioning
  config.vm.provision :shell, :path => "puppet/shell/initial-setup.sh"
  config.vm.provision :shell, :path => "puppet/shell/update-puppet.sh"
  config.vm.provision :shell, :path => "puppet/shell/librarian-puppet-vagrant.sh"

  # Puppet Provisioning
  settings[vagrant_vm]['vm']['provision'].each do |prov, options|
    config.vm.provision prov.to_sym do |item|
      if prov == "puppet"
        item.facter = {
          "ssh_username" => "vagrant"
        }
      end

      if !options['manifests_path'].nil?
        item.manifests_path = options['manifests_path']
      end

      if !options['module_path'].nil?
        item.module_path = options['module_path']
      end

      if !options['manifest_file'].nil?
        item.manifest_file = options['manifest_file']
      end

      if !options['options'].nil?
        opt = options['options']
      else
        opt = Array.new
      end

      if !opt.any? { |o| o.include? "--hiera_config" } 
        opt.push('--hiera_config /vagrant/puppet/hiera/hiera.yaml')
      end

      if !opt.any? { |o| o.include? "--parser" } 
        opt.push('--parser future')
      end

      if !opt.any? { |o| o.include? "--modulepath" } 
        opt.push('--modulepath /vagrant/puppet/modules:/etc/puppet/modules:/usr/share/puppet/modules')
      end

      item.options = opt
    end
  end


  # SSH Configuration
  settings[vagrant_vm]['ssh'].each do |item, value|
    if !value.nil?
      config.ssh.send("#{item}=", value)
    end
  end

  # Vagrant Configuration
  settings[vagrant_vm]['vagrant'].each do |item, value|
    if !value.nil?
      config.vagrant.send("#{item}=", /:(.+)/ =~ value ? $1.to_sym : value)
    end
  end
end

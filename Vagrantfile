# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

dir = Dir.pwd
vagrant_dir = File.expand_path(File.dirname(__FILE__))
protobox_boot = 'data/config/.protobox'

# Check if protobox boot file exists, if it doesn't create it here
if !File.file?(protobox_boot)
  File.open(protobox_boot, 'w') do |file|
    file.write('data/config/common.yml')
  end
end

# Check for boot file
if !File.file?(protobox_boot)
  puts "Boot file is missing: #{protobox_boot}\n"
  exit
end

# Open config file location
vagrant_file = ''
File.open(protobox_boot, 'r') do |f1|  
  while line = f1.gets  
    vagrant_file += line  
  end  
end 

# Check for missing data file
if !File.file?(vagrant_file)
  puts "Data file is missing: #{vagrant_file}\n"
  exit
end

# Load settings into memory
settings = YAML.load_file(vagrant_file)

# Start vagrant configuration
Vagrant.configure("2") do |config|

  # Store the current version of Vagrant for use in conditionals when dealing
  # with possible backward compatible issues.
  vagrant_version = Vagrant::VERSION.sub(/^v/, '')

  # Vagrant settings variable
  vagrant_vm = 'vagrant'

  # Check for box settings
  if settings[vagrant_vm].nil? or settings[vagrant_vm].nil?
    puts "Invalid yml data: #{vagrant_file}\n"
    exit
  end

  # Default Box
  config.vm.box = settings[vagrant_vm]['vm']['box']
  config.vm.box_url = settings[vagrant_vm]['vm']['box_url']

  # Hostname
  if !settings[vagrant_vm]['vm']['hostname'].nil?
    config.vm.hostname = settings[vagrant_vm]['vm']['hostname']
  end
 
  # Ports and IP Address
  if !settings[vagrant_vm]['vm']['usable_port_range'].nil?
    ends = settings[vagrant_vm]['vm']['usable_port_range'].to_s.split('..').map{|d| Integer(d)}
    config.vm.usable_port_range = (ends[0]..ends[1])
  end

  # network IP
  config.vm.network :private_network, ip: settings[vagrant_vm]['vm']['network']['private_network'].to_s

  # Forwarded ports
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

      if nfs
        config.vm.synced_folder folder['source'], folder['target'], id: id, disabled: dis, :nfs => { :mount_options => opt }
      else
        config.vm.synced_folder folder['source'], folder['target'], id: id, disabled: dis, owner: own, group: grp, :mount_options => opt
      end
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

  # Ansible Provisioning
  if settings[vagrant_vm]['vm']['provision'].has_key?("ansible")
    ansible = settings[vagrant_vm]['vm']['provision']['ansible']
    playbook = "/vagrant/" + ansible['playbook']

    params = Array.new
    params << playbook

    if !ansible['inventory'].nil?
      params << "-i \\\"" + ansible['inventory'] + "\\\""
    end

    if !ansible['verbose'].nil?
      if ansible['verbose'] == 'vv' or ansible['verbose'] == 'vvv' or ansible['verbose'] == 'vvvv'
        params << "-" + ansible['verbose']
      else
        params << "--verbose"
      end
    end

    params << "--connection=local"

    if ansible['extra-vars'].nil?
      extra_vars = Hash.new
    end

    extra_vars['protobox_env'] = 'vagrant'
    extra_vars['protobox_config'] = "/vagrant/" + vagrant_file

    params << "--extra-vars=\\\"" + extra_vars.map{|k,v| "#{k}=#{v}"}.join(' ').gsub("\"","\\\"") + "\\\"" unless extra_vars.empty?
    
    config.vm.provision :shell, :path => "ansible/shell/initial-setup.sh", :args => "-a \"" + params.join(" ") + "\""
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

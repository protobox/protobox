# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require File.expand_path(File.dirname(__FILE__) + '/lib/shell/build-protobox')
require File.expand_path(File.dirname(__FILE__) + '/lib/shell/build-playbook')
require File.expand_path(File.dirname(__FILE__) + '/lib/shell/build-dashboard')

dir = Dir.pwd
vagrant_dir = File.expand_path(File.dirname(__FILE__))
protobox_dir = vagrant_dir + '/.protobox'
protobox_boot = protobox_dir + '/config'
ansible_version = protobox_dir + '/ansible_version'

cli_file = vagrant_dir + '/.protobox_cli'
cli_version = File.open(cli_file) {|f| f.readline}

# Check vagrant version
if Vagrant::VERSION < "1.5.0"
  puts "Please upgrade to vagrant 1.5+: "
  puts "http://www.vagrantup.com/downloads.html"
  puts 
  exit
end

# Check for protobox plugin
if !Vagrant.has_plugin?('vagrant-protobox')
  puts "Protobox vagrant plugin missing, run the following: "
  puts 
  puts "vagrant plugin install vagrant-protobox"
  puts
  exit
end

# Check for protobox cli updates
if VagrantPlugins::Protobox::VERSION < cli_version
  puts "Please update your protobox cli tools: "
  puts 
  puts "vagrant plugin update vagrant-protobox"
  puts
  exit
end

# Create protobox dir if it doesn't exist
if !File.directory?(protobox_dir)
  Dir.mkdir(protobox_dir)
end

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
vagrant_file = File.open(protobox_boot) {|f| f.readline.chomp}

# Check for missing data file
if !File.file?(vagrant_dir + '/' + vagrant_file)
  puts "Data file is missing: #{vagrant_dir}/#{vagrant_file}\n"
  puts "You may need to switch your config: ruby protobox switch [config]"
  exit
end

# Load settings into memory
settings = YAML.load_file(vagrant_dir + '/' + vagrant_file)

# Build protobox files
protobox_playbook = build_protobox(settings, protobox_dir)

# Build the playbook
playbook = build_playbook(settings, protobox_dir)

# Build the dashboard
dashboard = build_dashboard(settings, protobox_dir)

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
  if settings[vagrant_vm]['vm'].has_key?("box") and !settings[vagrant_vm]['vm']['box'].nil?
    config.vm.box = settings[vagrant_vm]['vm']['box']
  end

  # Box URL
  if settings[vagrant_vm]['vm'].has_key?("box_url") and !settings[vagrant_vm]['vm']['box_url'].nil?
    config.vm.box_url = settings[vagrant_vm]['vm']['box_url']
  end

  # Box version
  if settings[vagrant_vm]['vm'].has_key?("box_version") and !settings[vagrant_vm]['vm']['box_version'].nil?
    config.vm.box_version = settings[vagrant_vm]['vm']['box_version']
  end

  # Box updates
  if settings[vagrant_vm]['vm'].has_key?("box_check_update") and !settings[vagrant_vm]['vm']['box_check_update'].nil?
    config.vm.box_check_update = settings[vagrant_vm]['vm']['box_check_update']
  end

  # Hostname
  if settings[vagrant_vm]['vm'].has_key?("hostname") and !settings[vagrant_vm]['vm']['hostname'].nil?
    config.vm.hostname = settings[vagrant_vm]['vm']['hostname']
  end

  # Ports and IP Address
  if settings[vagrant_vm]['vm'].has_key?("usable_port_range") and !settings[vagrant_vm]['vm']['usable_port_range'].nil?
    ends = settings[vagrant_vm]['vm']['usable_port_range'].to_s.split('..').map{|d| Integer(d)}
    config.vm.usable_port_range = (ends[0]..ends[1])
  end

  # network IP
  config.vm.network :private_network, ip: settings[vagrant_vm]['vm']['network']['private_network'].to_s

  # Forwarded ports
  if settings[vagrant_vm]['vm']['network'].has_key?("forwarded_port") and !settings[vagrant_vm]['vm']['network']['forwarded_port'].nil?
    settings[vagrant_vm]['vm']['network']['forwarded_port'].each do |item, port|
      if !port['guest'].nil? and 
         !port['host'].nil? and 
         !port['guest'].empty? and 
         !port['host'].empty?
        config.vm.network :forwarded_port, guest: Integer(port['guest']), host: Integer(port['host'])
      end
    end
  end

  # Synced Folders
  if settings[vagrant_vm]['vm'].has_key?("synced_folder") and !settings[vagrant_vm]['vm']['synced_folder'].nil?
    settings[vagrant_vm]['vm']['synced_folder'].each do |item, folder|
      if !folder['source'].nil? and !folder['target'].nil?
        type = !folder['type'].nil? ? folder['type'] : 'nfs'
        create = !folder['create'].nil? ? folder['create'] : false
        disabled = !folder['disabled'].nil? ? folder['disabled'] : false

        # backwards compat: check if using nfs
        if !folder['nfs'].nil? and folder['nfs']
          type = 'nfs'
        end

        # NFS
        if type == 'nfs'
          nfs_udp = !folder['nfs_udp'].nil? ? folder['nfs_udp'] : true
          nfs_version = !folder['nfs_version'].nil? ? folder['nfs_version'] : 3

          config.vm.synced_folder folder['source'], folder['target'], 
            type: type, 
            create: create,
            disabled: disabled, 
            nfs_udp: nfs_udp, 
            nfs_version: nfs_version
        
        # RSYNC
        elsif type == 'rsync'
          rsync_args = !folder['rsync__args'].nil? ? folder['rsync__args'] : ["--verbose", "--archive", "--delete", "-z"]
          rsync_auto = !folder['rsync__auto'].nil? ? folder['rsync__auto'] : true
          rsync_exclude = !folder['rsync__exclude'].nil? ? folder['rsync__exclude'] : [".vagrant/"]

          config.vm.synced_folder folder['source'], folder['target'], 
            type: type, 
            create: create,
            disabled: disabled, 
            rsync__args: rsync_args, 
            rsync__auto: rsync_auto, 
            rsync__exclude: rsync_exclude
        
        # No type found, use old method
        else
          #puts "Missing Type: " + type
          owner = !folder['owner'].nil? ? folder['owner'] : ''
          group = !folder['group'].nil? ? folder['group'] : ''
          mount_options = !folder['mount_options'].nil? ? folder['mount_options'] : Array.new

          config.vm.synced_folder folder['source'], folder['target'], 
            create: create,
            disabled: disabled, 
            owner: owner, 
            group: group, 
            :mount_options => mount_options
        end
      end
    end
  end

  # Provider Configuration
  if settings[vagrant_vm]['vm'].has_key?("provider") and !settings[vagrant_vm]['vm']['provider'].nil?
    # Loop through provders
    settings[vagrant_vm]['vm']['provider'].each do |prov, options|
      # Set specific provider info
      config.vm.provider prov.to_sym do |params|
        # Loop through provider options
        options.each do |type, values|
          # Check if option has suboptions
          if values.is_a?(Hash) 
            values.each do |key, value|
              params.customize [type, :id, "--#{key}", value]
            end
          # Set key=value options
          else
            params.send("#{type}=", values)
          end
        end
      end
    end
  end

  # Ansible Provisioning
  if settings[vagrant_vm]['vm']['provision'].has_key?("ansible")
    ansible = settings[vagrant_vm]['vm']['provision']['ansible']

    if (ansible['playbook'] == "default" or ansible['playbook'] == "ansible/site.yml") and playbook
      playbook_path = "/vagrant/.protobox/playbook"
    else
      playbook_path = "/vagrant/" + ansible['playbook']
    end

    params = Array.new
    params << playbook_path

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

    if !ansible['extra_vars'].nil?
      extra_vars = ansible['extra_vars']
    else
      extra_vars = Hash.new
    end

    extra_vars['protobox_env'] = "vagrant"
    extra_vars['protobox_config'] = "/vagrant/" + vagrant_file

    params << "--extra-vars=\\\"" + extra_vars.map{|k,v| "#{k}=#{v}"}.join(" ").gsub("\"","\\\\\"") + "\\\"" unless extra_vars.empty?

    config.vm.provision :shell, :path => "lib/shell/initial-setup.sh", :args => "-a \"" + params.join(" ") + "\"", :keep_color => true
  end 

  # Finishing provisioner
  config.vm.provision :shell, :inline => <<-PREPARE
    /bin/cat /vagrant/lib/shell/logo.txt
    DASHBOARD=( $( /bin/cat /vagrant/.protobox/dashboard ) )
    if [[ ! -z "$DASHBOARD" ]]; then
      echo "Dashboard: $DASHBOARD"
    fi
  PREPARE

  # SSH Configuration
  if settings[vagrant_vm].has_key?("ssh") and !settings[vagrant_vm]['ssh'].nil?
    settings[vagrant_vm]['ssh'].each do |item, value|
      if !value.nil?
        config.ssh.send("#{item}=", value)
      end
    end
  end

  # Vagrant Configuration
  if settings[vagrant_vm].has_key?("vagrant") and !settings[vagrant_vm]['vagrant'].nil?
    settings[vagrant_vm]['vagrant'].each do |item, value|
      if !value.nil?
        config.vagrant.send("#{item}=", /:(.+)/ =~ value ? $1.to_sym : value)
      end
    end
  end
end

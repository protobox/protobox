class IDEError < Vagrant::Errors::VagrantError
  def initialize(message = "IDE Error")
    #super
    StandardError.instance_method(:initialize).bind(self).call(message)
  end
end

class IDE
  def self.configure(config)
    @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '../'))
    @protobox_dir = File.join(@root_dir, '.protobox')
    @protobox_config = File.join(@root_dir, 'config.yml')

    # Check vagrant version
    if Vagrant::VERSION < "1.5.0"
      msg = "Please upgrade to vagrant 1.5+:\n"
      msg += "http://www.vagrantup.com/downloads.html\n"

      raise IDEError, msg
    end

    # Create protobox dir if it doesn't exist
    if !File.directory?(@protobox_dir)
      Dir.mkdir(@protobox_dir)
    end

    # Check for boot file
    if !File.file?(@protobox_config)
      raise IDEError, "Config file is missing: #{@protobox_config}\n"
    end

    # Store the current version of Vagrant for use in conditionals when dealing
    # with possible backward compatible issues.
    @vagrant_version = Vagrant::VERSION.sub(/^v/, '')

    # Open config file location
    settings = YAML.load_file(@protobox_config)

    # Build protobox files
    self.build_protobox(settings)

    # Build the playbook
    self.build_playbook(settings)

    # Build the galaxy file
    self.build_galaxyfile(settings)

    # Build the dashboard
    self.build_dashboard(settings)

    # Default Box
    if settings['vagrant'].has_key?("box") and !settings['vagrant']['box'].nil?
      config.vm.box = settings['vagrant']['box']
    end

    # Box URL
    if settings['vagrant'].has_key?("box_url") and !settings['vagrant']['box_url'].nil?
      config.vm.box_url = settings['vagrant']['box_url']
    end

    # Box version
    if settings['vagrant'].has_key?("box_version") and !settings['vagrant']['box_version'].nil?
      config.vm.box_version = settings['vagrant']['box_version']
    end

    # Box updates
    if settings['vagrant'].has_key?("box_check_update") and !settings['vagrant']['box_check_update'].nil?
      config.vm.box_check_update = settings['vagrant']['box_check_update']
    end

    # Hostname
    if settings['vagrant'].has_key?("hostname") and !settings['vagrant']['hostname'].nil?
      config.vm.hostname = settings['vagrant']['hostname']
    end

    # Ports and IP Address
    if settings['vagrant'].has_key?("usable_port_range") and !settings['vagrant']['usable_port_range'].nil?
      ends = settings['vagrant']['usable_port_range'].to_s.split('..').map{|d| Integer(d)}
      config.vm.usable_port_range = (ends[0]..ends[1])
    end

    # network IP
    config.vm.network :private_network, ip: settings['vagrant']['ip'].to_s

    # Forwarded ports
    if settings['vagrant'].has_key?("ports") and !settings['vagrant']['ports'].nil?
      settings['vagrant']['ports'].each do |item, port|
        if !port['guest'].nil? and 
           !port['host'].nil? and 
           !port['guest'].empty? and 
           !port['host'].empty?
          config.vm.network :forwarded_port, guest: Integer(port['guest']), host: Integer(port['host']), protocol: port["protocol"] ||= "tcp"
        end
      end
    end

    # Configure The Public Key For SSH Access
    #config.vm.provision "shell" do |s|
    #  s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
    #  s.args = [File.read(File.expand_path(settings["authorize"]))]
    #end

    # Copy The SSH Private Keys To The Box
    #settings['vagrant']["keys"].each do |key|
    #  config.vm.provision "shell" do |s|
    #    s.privileged = false
    #    s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
    #    s.args = [File.read(File.expand_path(key)), key.split('/').last]
    #  end
    #end

    # Register All Of The Configured Shared Folders
    #settings["folders"].each do |folder|
    #  config.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil
    #end

    # Synced Folders
    if settings['vagrant'].has_key?("folders") and !settings['vagrant']['folders'].nil?
      settings['vagrant']['folders'].each do |item, folder|
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
    
    config.vm.provider "virtualbox" do |prov|
      if settings['vagrant'].has_key?("hostname") and !settings['vagrant']['hostname'].nil?
        prov.name = settings['vagrant']['hostname']
      end
      prov.customize ["modifyvm", :id, "--memory", settings['vagrant']["memory"] ||= "2048"]
      prov.customize ["modifyvm", :id, "--cpus", settings['vagrant']["cpus"] ||= "1"]
      prov.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      prov.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      #prov.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
    end

    if settings['vagrant'].has_key?("provider") and !settings['vagrant']['provider'].nil?
      # Loop through provders
      settings['vagrant']['provider'].each do |prov, options|
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
    ansible_params = Array.new

    if !settings['ansible'].nil? and !settings['ansible']['playbook'].nil? and settings['ansible']['playbook'] != "default"
      playbook_path = "/vagrant/" + settings['ansible']['playbook']
    else
      playbook_path = "/vagrant/.protobox/playbook"
    end

    ansible_params << playbook_path

    if !settings['ansible'].nil? and !settings['ansible']['inventory'].nil?
      ansible_params << "-i \"" + ansible['inventory'] + "\""
    end

    if !settings['ansible'].nil? and !settings['ansible']['verbose'].nil?
      if settings['ansible']['verbose'] == 'vv' or settings['ansible']['verbose'] == 'vvv' or ansible['verbose'] == 'vvvv'
        ansible_params << "-" + settings['ansible']['verbose']
      else
        ansible_params << "--verbose"
      end
    end

    ansible_params << "--connection=local"

    if !settings['ansible'].nil? and !settings['ansible']['extra_vars'].nil?
      extra_vars = ansible['extra_vars']
    else
      extra_vars = Hash.new
    end

    extra_vars['protobox_env'] = "vagrant"
    #extra_vars['protobox_config'] = "/vagrant/" + vagrant_file

    ansible_params << "--extra-vars=\"" + extra_vars.map{|k,v| "#{k}=#{v}"}.join(" ").gsub("\"","\\\"") + "\"" unless extra_vars.empty?

    config.vm.provision :shell, :path => "lib/initial-setup.sh", :keep_color => true

    # Write the ansible arguments
    File.open(File.join(@protobox_dir, 'ansible_args'), "w") do |f|
      f.write(ansible_params.join(" "))
    end

    # Finishing provisioner
    config.vm.provision :shell, :inline => <<-PREPARE
      /bin/cat /vagrant/lib/logo.txt
      DASHBOARD=( $( /bin/cat /vagrant/.protobox/dashboard ) )
      if [[ ! -z "$DASHBOARD" ]]; then
        echo "Dashboard: $DASHBOARD"
      fi
    PREPARE

    # SSH Configuration
    if settings['vagrant'].has_key?("ssh") and !settings['vagrant']['ssh'].nil?
      settings['vagrant']['ssh'].each do |item, value|
        if !value.nil?
          config.ssh.send("#{item}=", value)
        end
      end
    end

    # Vagrant Configuration
    if settings['vagrant'].has_key?("config") and !settings['vagrant']['config'].nil?
      settings['vagrant']['config'].each do |item, value|
        if !value.nil?
          config.vagrant.send("#{item}=", /:(.+)/ =~ value ? $1.to_sym : value)
        end
      end
    end

  end

  def self.build_protobox(yaml)
    # Ansible version
    ansible_version = 'latest'
    if !yaml['ansible'].nil? and !yaml['ansible']['version'].nil?
      ansible_version = yaml['ansible']['version'].to_s
    end

    # Dump out the contents
    File.open(File.join(@protobox_dir, 'ansible_version'), "w") do |f|
      f.write(ansible_version)
    end

    return true
  end

  def self.build_playbook(yaml)
    out = []

    play = {}
    play['name'] = 'Core'
    play['hosts'] = 'all'
    #play['sudo'] = true
    #play['sudo_user'] = 'root'
    #play['vars_files'] = ['{{ protobox_config }}']
    
    play['roles'] = []

    if !yaml['modules'].nil?
      yaml['modules'].each do |mod|
        entry = {}

        # skip if not supposed to run
        if !mod['autorun'].nil? and mod['autorun'] == 'false'
          next
        end

        if mod['source'] == 'protobox'
          entry['role'] = 'protobox.' + mod['name']
        elsif mod['source'] == 'git'
          entry['role'] = mod['name']
        elsif mod['source'] == 'ansible-galaxy'
          entry['role'] = mod['name']
        end

        # Load in config if specified
        if !mod['config'].nil?
          file_path = self.get_local_path(mod['config'])
          if File.exists?(file_path)
            mod_config = YAML.load_file(file_path)
            entry.merge!(mod_config)
          end
        end

        play['roles'].push(entry)
      end
    end

    out << play

    # Dump out the contents
    File.open(File.join(@protobox_dir, 'playbook'), 'w') do |file|
      YAML::dump(out, file)
    end

    return true
  end

  def self.get_local_path(path)
    path.gsub! '@', @root_dir + '/'
    return path
  end

  def self.build_galaxyfile(yaml)
    if yaml['modules'].nil?
      return false
    end

    out = []

    yaml['modules'].each do |mod|
      role = {}

      if mod['source'] == 'protobox'
        role['src'] = 'https://github.com/protobox/ansible-' + mod['name'] + ''
        role['version'] = 'master'
        role['name'] = 'protobox.' + mod['name']
      elsif mod['source'] == 'git'
        role['src'] = self.convert_git_source(mod['repository'])
        role['version'] = 'master'
        role['name'] = mod['name']
      elsif mod['source'] == 'ansible-galaxy'
        role['src'] = mod['name']
      end

      out.push(role)
    end

    # Dump out the contents
    File.open(File.join(@protobox_dir, 'ansible_requirements.yml'), 'w') do |file|
      YAML::dump(out, file)
    end
  end

  def self.convert_git_source(source)
    source.gsub! 'git@github.com:', 'https://github.com/'
    return source
  end

  def self.build_dashboard(yaml)
    return false

    protobox_dashboard = File.join(@protobox_dir, 'dashboard')

    if !yaml['vagrant']['vm']['network']['private_network'].nil?
      ip = yaml['vagrant']['vm']['network']['private_network']
    else
      ip = nil
    end

    # Write the dashboard file
    File.open(protobox_dashboard, 'w') do |file|
      file.write('http://' + ip + '/')
    end

    #
    # Build json
    #

    # Exit out here if the dashboard should not be installed
    if !yaml['protobox']['dashboard'].nil? and yaml['protobox']['dashboard']['install'].to_i != 1
      return false
    end

    #synced_path = ''
    #if !yaml['vagrant']['vm']['synced_folder'].nil?
    #  yaml['vagrant']['vm']['synced_folder'].each do |item, map|
    #    if !map['target'].nil?
    #      synced_path = map['target'] << '/' unless map['target'].end_with?('/')
    #    end
    #  end
    #end

    data_path = nil

    if !yaml['protobox']['dashboard'].nil? and !yaml['protobox']['dashboard']['path'].nil?
      if yaml['vagrant']['vm'].has_key?("synced_folder")
        yaml['vagrant']['vm']['synced_folder'].each { |share,data|
          next if data['source'].nil? or data['target'].nil?
          share_source = data['source']
          share_target = data['target']

          if yaml['protobox']['dashboard']['path'].start_with?(share_target)
            local_path = File.expand_path(yaml['protobox']['dashboard']['path'].gsub(/^#{share_target}/, share_source).prepend('../../'), File.dirname(__FILE__))
            local_path = local_path << '/' unless local_path.end_with?('/')
            data_path = local_path if File.directory?(local_path)
          end

          break unless data_path.nil?
        }
      end
    else
      data_path =  File.expand_path('/../../web/protobox/', File.dirname(__FILE__))
    end

    # Exit out here if the path does not exist
    if data_path.nil? or !File.directory?(data_path)
      #Dir.mkdir(data_path)
      return false
    end

    # Websites
    websites = []

    if !yaml['apache'].nil? and yaml['apache']['install'] == 1
      yaml['apache']['vhosts'].each do |vhost|
        if (vhost['ssl'] != 1)
          websites.push({
            :name => vhost['name'],
            :site => "http://" + vhost['servername'] + (vhost['port'].to_i != 80 ? ':' + vhost['port'].to_s : '')
          })
        else
          websites.push({
            :name => vhost['name'],
            :site => "https://" + vhost['servername'] + (vhost['port'].to_i != 443 ? ':' + vhost['port'].to_s : '')
          })
        end
      end
    end

    if !yaml['nginx'].nil? and yaml['nginx']['install'] == 1
      yaml['nginx']['vhosts'].each do |vhost|
        if (vhost['ssl'] != 1)
          websites.push({
            :name => vhost['name'],
            :site => "http://" + vhost['server_name'] + (vhost['listen_port'].to_i != 80 ? ':' + vhost['listen_port'].to_s : '')
          })
        else
          websites.push({
            :name => vhost['name'],
            :site => "https://" + vhost['server_name'] + (vhost['listen_port'].to_i != 443 ? ':' + vhost['listen_port'].to_s : '')
          })
        end
      end
    end

    # Databases
    databases = []

    if !yaml['mysql'].nil? and yaml['mysql']['install'] == 1
      yaml['mysql']['databases'].each do |vhost|
        databases.push({
          :name => vhost['name'], 
          :type => "mysql"
        })
      end
    end

    if !yaml['mariadb'].nil? and yaml['mariadb']['install'] == 1
      yaml['mariadb']['databases'].each do |vhost|
        databases.push({
          :name => vhost['name'], 
          :type => "mariadb"
        })
      end
    end

    if !yaml['postgresql'].nil? and yaml['postgresql']['install'] == 1
      yaml['postgresql']['databases'].each do |vhost|
        databases.push({
          :name => vhost['name'], 
          :type => "postgresql"
        })
      end
    end

    # Build document
    document = {
      "version" => yaml['protobox']['version'],
      "sites" => websites,
      "databases" => databases
    }

    # Write the protobox web file
    File.open(data_path + "data.json", "w") do |f|
      #f.write(document.to_json)
      f.write(JSON.pretty_generate(document))
    end

    return true
  end
end
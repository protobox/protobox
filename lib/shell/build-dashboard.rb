def build_dashboard(yaml, protobox_dir)
  protobox_dashboard = protobox_dir + '/dashboard'

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
      websites.push({
        :name => vhost['name'], 
        :site => "http://" + vhost['servername'] + (vhost['port'].to_i != 80 ? ':' + vhost['port'].to_s : '')
      })
    end
  end

  if !yaml['nginx'].nil? and yaml['nginx']['install'] == 1
    yaml['nginx']['vhosts'].each do |vhost|
      websites.push({
        :name => vhost['name'], 
        :site => "http://" + vhost['server_name'] + (vhost['listen_port'].to_i != 80 ? ':' + vhost['listen_port'].to_s : '')
      })
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

#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'yaml'
require 'json'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: finish-setup.rb [options]"

  opts.on('-s', '--source [PATH]', 'Source YAML Path') do |v|
    options[:source_url] = v
  end

  opts.on('-l', '--logo [PATH]', 'Logo Path') do |v|
    options[:logo_url] = v
  end

  opts.on_tail("-h", "--help", "Help") do
    puts opts
    exit
  end
end.parse!

yaml_file = options[:source_url]

if yaml_file.nil? or !File.file?(yaml_file)
  exit
end

logo_file = options[:logo_url]

if logo_file.nil? or !File.file?(logo_file)
  exit
end

File.open(logo_file, 'r') do |f1|
  while line = f1.gets
    puts line
  end
end

data = YAML::load_file(yaml_file);

if !data['vagrant']['vm']['network']['private_network'].nil?
  ip = data['vagrant']['vm']['network']['private_network']
else
  ip = nil
end

if !ip.nil?
  puts "\nDashboard: http://" + ip + "/\n"
end

#
# Build json
#

# Websites
websites = []

if !data['apache'].nil? and data['apache']['install'] == 1
  data['apache']['vhosts'].each do |vhost|
    websites.push({
      :name => vhost['name'],
      :site => "http://" + vhost['servername'] + (vhost['port'].to_i != 80 ? ':' + vhost['port'] : '')
    })
  end
end

if !data['nginx'].nil? and data['nginx']['install'] == 1
  data['nginx']['vhosts'].each do |vhost|
    websites.push({
      :name => vhost['name'],
      :site => "http://" + vhost['server_name'] + (vhost['port'].to_i != 80 ? ':' + vhost['port'] : '')
    })
  end
end

# Databases
databases = []

if !data['mysql'].nil? and data['mysql']['install'] == 1
  data['mysql']['databases'].each do |vhost|
    databases.push({
      :name => vhost['name'],
      :type => "mysql"
    })
  end
end

if !data['mariadb'].nil? and data['mariadb']['install'] == 1
  data['mariadb']['databases'].each do |vhost|
    databases.push({
      :name => vhost['name'],
      :type => "mariadb"
    })
  end
end

if !data['postgresql'].nil? and data['postgresql']['install'] == 1
  data['postgresql']['databases'].each do |vhost|
    databases.push({
      :name => vhost['name'],
      :type => "postgresql"
    })
  end
end

# Build document
document = {
  "version" => data['protobox']['version'],
  "sites" => websites,
  "databases" => databases
}

File.open("/srv/www/web/protobox/data.json", "w") do |f|
  #f.write(document.to_json)
  f.write(JSON.pretty_generate(document))
end

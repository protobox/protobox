#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

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

puts "\nYou can now access your websites at:\n"

data = YAML::load_file(yaml_file);

if !data['apache'].nil? and data['apache']['install'] == 1
  data['apache']['vhosts'].each do |vhost|
    puts "http://" + vhost['servername'] + "\n"
  end
end

if !data['nginx'].nil? and data['nginx']['install'] == 1
  data['nginx']['vhosts'].each do |vhost|
    puts "http://" + vhost['server_name'] + "\n"
  end
end


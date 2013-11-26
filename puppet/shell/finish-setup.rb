#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: build-puppetfile.rb [options]"

  opts.on('-s', '--source URL', 'Source URL') { |v| options[:source_url] = v }
  opts.on('-l', '--logo URL', 'Logo URL') { |v| options[:logo_url] = v }
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
	data['apache']['vhosts'].each do |key, vhost|
		puts "http://" + vhost['servername'] + "\n"
	end
end

if !data['nginx'].nil? and data['nginx']['install'] == 1
	data['apache']['server_name'].each do |key, vhost|
		puts "http://" + vhost['servername'] + "\n"
	end
end


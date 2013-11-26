#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: build-puppetfile.rb [options]"

  opts.on('-s', '--source URL', 'Source URL') { |v| options[:source_url] = v }
end.parse!

yaml_file = options[:source_url]

if yaml_file.nil? or !File.file?(yaml_file)
	exit
end

#puts "\#Location: #{yaml_file}"

data = YAML::load_file(yaml_file);

if !data['puppetfile']['forge'].nil?
	puts "forge \"" + data['puppetfile']['forge'] + "\"\n"
end

data['puppetfile']['modules'].each do |item, mod|
	line = "mod '" + item + "'"

	if !mod['git'].nil?
		line += ", :git => '" + mod['git'] + "'"
	end

	if !mod['ref'].nil?
		line += ", :ref => '" + mod['ref'] + "'"
	end

	if !mod['path'].nil?
		line += ", :path => '" + mod['path'] + "'"
	end

	puts line + "\n"
end

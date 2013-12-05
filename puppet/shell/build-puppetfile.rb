#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: build-puppetfile.rb [options]"

  opts.on('-s', '--source [PATH]', 'Source YAML Path') do |v| 
  	options[:source_url] = v
  end

  opts.on_tail("-h", "--help", "Help") do
    puts opts
    exit
  end
end.parse!

yaml_file = options[:source_url]

if yaml_file.nil? or !File.file?(yaml_file)
	puts "YAML file is missing"
	exit
end

#puts "\#Location: #{yaml_file}"

data = YAML::load_file(yaml_file);

body = <<HEAD
# DO NOT EDIT
# This file is automatically built by protobox during setup
#
# This is the Puppetfile to manage puppet module dependencies.

# Shortcut for a module from GitHub's protobox
def protobox(name, *args)
  options ||= if args.last.is_a? Hash
    args.last
  else
    {}
  end

  if path = options.delete(:path)
    mod name, :path => path
  else
    version = args.first
    options[:repo] ||= "protobox/protobox-\#{name}"
    mod name, version, :github_tarball => options[:repo]
  end
end
HEAD

if !data['puppetfile']['forge'].nil?
	body += "\nforge \"" + data['puppetfile']['forge'] + "\"\n"
end

core_modules = {
	"protobox" => false,
	"stdlib"   => false,
	"concat"   => false,
	"apt" 	   => false,
	"yum"      => false,
	"vcsrepo"  => false,
	"ntp"      => false
}

data['puppetfile']['modules'].each do |item, mod|
	if !core_modules[item].nil?
		core_modules[item] = true
	end
end

if !core_modules["protobox"]
	body += "\n# Includes many of our providers, as well as global config.\n# Required."
	body += "\nmod \"protobox\", :git => 'git://github.com/protobox/puppet-protobox.git'\n"
end

body += "\n# Core modules\n"

puts core_modules["stdlib"]

if !core_modules["stdlib"]
	body += "mod \"stdlib\", :git => 'git://github.com/puphpet/puppetlabs-stdlib.git'\n"
end

if !core_modules["concat"]
	body += "mod \"concat\", :git => 'git://github.com/puphpet/puppetlabs-concat.git'\n"
end

if !core_modules["apt"]
	body += "mod \"apt\", :git => 'git://github.com/puphpet/puppetlabs-apt.git'\n"
end

if !core_modules["yum"]
	body += "mod \"yum\", :git => 'git://github.com/puphpet/puppet-yum.git'\n"
end

if !core_modules["vcsrepo"]
	body += "mod \"vcsrepo\", :git => 'git://github.com/puphpet/puppetlabs-vcsrepo.git'\n"
end

if !core_modules["ntp"]
	body += "mod \"ntp\", :git => 'git://github.com/puphpet/puppetlabs-ntp.git'\n"
end

# build puppet modules from file
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

	body += line + "\n"
end

# output the puppetfile
puts body

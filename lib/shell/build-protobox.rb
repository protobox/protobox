def build_protobox(yaml, protobox_dir)
  ansible_version_file = protobox_dir + '/ansible_version'

  # Ansible version
  ansible_version = 'latest'
  if !yaml['protobox'].nil? and !yaml['protobox']['ansible'].nil? and !yaml['protobox']['ansible']['version'].nil?
    ansible_version = yaml['protobox']['ansible']['version'].to_s
  end

  # Dump out the contents
  File.open(ansible_version_file, "w") do |f|
    f.write(ansible_version)
  end

  return true
end
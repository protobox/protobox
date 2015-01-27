#!/usr/bin/python

import yaml

import threading
import subprocess
import traceback
import shlex
 
 
class Command(object):
    """
    Enables to run subprocess commands in a different thread with TIMEOUT option.

    Based on jcollado's solution:
    http://stackoverflow.com/questions/1191374/subprocess-with-timeout/4825933#4825933
    """
    command = None
    process = None
    status = None
    output, error = '', ''
 
    def __init__(self, command):
        if isinstance(command, basestring):
            command = shlex.split(command)
        self.command = command
 
    def run(self, timeout=None, **kwargs):
        """ Run a command then return: (status, output, error). """
        def target(**kwargs):
            try:
                self.process = subprocess.Popen(self.command, **kwargs)
                self.output, self.error = self.process.communicate()
                self.status = self.process.returncode
            except:
                self.error = traceback.format_exc()
                self.status = -1
        # default stdout and stderr
        if 'stdout' not in kwargs:
            kwargs['stdout'] = subprocess.PIPE
        if 'stderr' not in kwargs:
            kwargs['stderr'] = subprocess.PIPE
        # thread
        thread = threading.Thread(target=target, kwargs=kwargs)
        thread.start()
        thread.join(timeout)
        if thread.is_alive():
            self.process.terminate()
            thread.join()
        return self.status, self.output, self.error

f = open('/vagrant/config.yml')
dataMap = yaml.safe_load(f)
f.close()

git_modules = []
galaxy_modules = []

""" Loop through yaml and build module list """
if isinstance(dataMap, dict):
	for group, list in dataMap.iteritems():
		if group == "modules":
			for module in list:
				if module["source"] == "protobox":
					git_modules.append({
						'source': 'git@github.com:protobox/ansible-' + module['name'] + '.git',
						'branch': 'master',
						'path': '/vagrant/ansible/protobox-' + module['name']
					})
				elif module["source"] == "git":
					git_modules.append({
						'source': module['repository'],
						'branch': 'master',
						'path': '/vagrant/ansible/git-' + module['name']
					})
				elif module["source"] == "ansible-galaxy":
					galaxy_modules.append({
						'name': module['name']
					})

""" Loop through and install git modules """
for module in git_modules:
	print "Installing", module['source'], "to", module['path']
	cmd = [ 'git', 'clone', module['source'], module['path'] ]
	print "Cmd:", ' '.join(cmd)
	command = Command(' '.join(cmd))
	#command.run(timeout=120)
	#print command

print git_modules
print galaxy_modules

""" Loop through yaml and build module list """
data = []
if isinstance(dataMap, dict):
	for group, list in dataMap.iteritems():
		if group == "modules":
			for module in list:
				if module["source"] == "protobox":
					data.append({
						'src': 'git@github.com:protobox/ansible-' + module['name'] + '.git',
						'version': 'master',
						'name': module['name']
					})
				elif module["source"] == "git":
					data.append({
						'src': module['repository'],
						'version': 'master',
						'name': module['name']
					})
				elif module["source"] == "ansible-galaxy":
					data.append({
						'src': module['name']
					})

print data

with open('/vagrant/.protobox/ansible_requirements.yml', 'w') as outfile:
    outfile.write( yaml.dump(data, default_flow_style=False) )

#ansible-galaxy install -r requirements.yml

print "Done"

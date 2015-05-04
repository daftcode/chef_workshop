group node['group']

user node['user']['name'] do 
	gid node['group']
	home "/home/#{node['user']['name']}"
	password node['user']['pass']
	shell '/bin/bash'
	supports :manage_home => true # creates the home directory
end
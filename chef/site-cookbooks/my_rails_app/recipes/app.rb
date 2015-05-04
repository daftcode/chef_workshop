bash 'bundler' do 
	user node['user']
	cwd node['app_path']
	code <<-EOH 
		export HOME=/home/#{node['user']}
	 	source ~/.profile
		rvm use default
		gem install bundler
		bundle install
	EOH
end
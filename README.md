# Chef Workshop

## Prerequisites 

Basic experience with Ruby on Rails

VirtualBox and Vagrant - if you're not familiar with Vagrant, follow Zhebr's awesome tutorial: https://github.com/Zhebr/vagrant_workshop

## What is Chef?

TLDR: Chef is a tool for infrastructure automation - it turns administrative tasks into Ruby code and lets you set up application config, deployment and server managemnent in one place.

## Why use Chef rather than a shell script for provisioning and configuration management?

Well, we can often get by just with a simple bash script but Chef's DSL can do so much for us that it's worth trying. Chef is:

* pure Ruby
* ready to scale
* idempotent by default
* ERB templates
* TDD for infrastructure
* lots of open source, ready recipes

## Installation

Ok. Let's start by cloning this repository,

	git clone https://github.com/grodowski/chef_workshop
	cd chef_workshop

initializing Vagrant to provide a VM for us

	vagrant init

and installing knife-solo, because every good chef needs a knife ;)

	gem install knife-solo
	
We will now setup default chef config (which in our case is only required for chef not to complain).

	knife configure -r . --defaults

Now let's initialise an empty kitchen in our app folder. We will use `knife solo` command and use chef locally (let's forget about chef-server and the whole infrastructure for now)

	knife solo init chef

## Vagrant setup

The `Vagrantfile` stores initial config for our test node

	Vagrant.configure(2) do |config|
	  # let's use a default ubuntu trusty box
	  config.vm.box = "ubuntu/trusty64"
	
	  config.vm.network "forwarded_port", guest: 80, host: 4567

	  config.vm.provider "virtualbox" do |vb|
	    vb.memory = "1024"
	    vb.name = "chef_workshop"
	  end

	  # tell Vagrant to use chef to set up our environment when booting the VM
	  config.vm.provision "chef_solo" do |chef|
	    chef.cookbooks_path = "chef/site-cookbooks"
	    chef.run_list = [
	      'recipe[my_rails_app]',
	      'recipe[my_rails_app::nginx]',
	      'recipe[my_rails_app::rvm]',
	      'recipe[my_rails_app::app]',
	    ]
	    chef.log_level = :debug 
		
		# node-specific attributes - this usually resides in Chef config in  'chef/nodes/node_name.json'
	    chef.json = {
	      app_path: '/vagrant',
	      nginx_server: 'localhost:3000',
	      user: 'vagrant',
	      group: 'vagrant',
	      rvm: {
	        version: '1.26',
	      },
	      ruby: {
	        version: '2.2.2',
	      },
	    }
	  end
	end

## Initialise our cookbook

Chef cookbooks are sets of rules (recipes), which define dependencies, actions and configurations for a given node to run our project. Let's init an empty cookbook

	cd chef
	knife cookbook create my_rails_app -o site-cookbooks

We can also start with setting our application name to the global cookbook config
	
	# attributes/default.rb
	
	default['app'] = 'dogify'

## Dependencies & Packages

Now we can add our first recipe. Let's edit `recipes/default.rb` and add all required dependencies to install via `apt-get`. We have picked some common Rails dependencies that may be useful for the purpose of this demo, not all are necessary though.

	# chef/site-cookbooks/my_rails_app/recipes/default.rb
	
	execute "apt-get update"
	
	package "git-core"
	package "curl"
	package "zlib1g-dev"
	package "build-essential"
	package "libssl-dev"
	package "libreadline-dev"
	package "libyaml-dev"
	package "libsqlite3-dev"
	package "sqlite3"
	package "nodejs"
	package "libxml2-dev"
	package "libxslt1-dev"
	package "libcurl4-openssl-dev"
	package "python-software-properties"
	package "libffi-dev"
	package "libgdbm-dev"
	package "libncurses5-dev"
	package "automake"
	package "libtool"
	package "bison"
	package "imagemagick"
	package "libmagickwand-dev"

Now when we run our Chef provisioner via `vagrant provision` and happily see all the dependencies installed on our guest VM.

## RVM and Ruby

We need Ruby to run our Rails application, so let's install it using RVM.

	# chef/site-cookbooks/my_rails_app/recipes/rvm.rb
	
	username = node['user']

	bash 'install rvm' do
	  user username
	  cwd "/home/#{username}"
	
	  code <<-EOH
	    export HOME=/home/#{username}
	    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
	    curl -L https://get.rvm.io | bash -s stable
	    source ~/.rvm/scripts/rvm
	    rvm install #{node['ruby']['version']}
	    rvm use --default #{node['ruby']['version']}
	  EOH
	
	  not_if { File.exists?("/home/#{username}/.rvm/VERSION") && `cat /home/#{username}/.rvm/VERSION`.start_with?(node['rvm']['version']) }
	end

Notice that the `not_if` method taking a block ensures that we run the Ruby setup only once.

## Running Bundler 

We would like Chef to install all Ruby dependencies for us by running `bundle install` every time the server is provisioned

	# chef/site-cookbooks/my_rails_app/recipes/app.rb
		
	bash 'bundler' do 
			user node['user']
			cwd node['app_path']
			code <<-EOH 
				export HOME=/home/#{node['user']}
			 	source ~/.profile # Chef uses a non-login shell - source RVM
				rvm use default
				gem install bundler
				bundle install
			EOH
		end

## Configuring Nginx

Dogify will use Puma as the app server and Nginx as a reverse-proxy - let's configure that too. Puma has been already bundled within the `Gemfile`, but it will not be visible to the outside world until we install `nginx`. 

	
	# chef/site-cookbooks/my_rails_app/recipes/nginx.rb
	
	package "nginx"

	# start nginx
	service "nginx" do
	  supports [:status, :restart]
	  action :start
	end

We also need to remove the default config file which usually occupies port 80 by default

	# chef/site-cookbooks/my_rails_app/recipes/nginx.rb
	...
	
	# remove default nginx config
	default_path = "/etc/nginx/sites-enabled/default"
	execute "rm -f #{default_path}" do
	  only_if { File.exists?(default_path) }
	end
	
	...

and create our own configuration template. This is where Chef's ERB interpolations come in handy

	# chef/site-cookbooks/my_rails_app/templates/nginx_app.conf.erb
	
	upstream <%= node['app'] %> {
	  server <%= node['nginx_server'] %>;
	}
	
	server {
	  listen 80;
	  root /home/<%= node['user'] %>/<%= node['app'] %>/current/public;
	
	  location / {
	    proxy_pass http://<%= node['app'] %>;
	    proxy_set_header Host $host;
	    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	  }
	}

We can see that this template can be reused on different nodes easily. Let's tell Chef to load it during the provisioning process

	# chef/site-cookbooks/my_rails_app/recipes/nginx.rb
	...
	
	# set custom nginx config for purifier_web
	template "/etc/nginx/sites-enabled/#{node['app']}" do
	  source "nginx_app.conf.erb"
	  mode 0644
	  owner node['user']
	  group node['group']
	  notifies :restart, "service[nginx]", :delayed
	end
	
	...

## Ready!

You've probably run `vagrant provision` multiple times up to now, but it's the time when everything should be up and running. Let's SSH into the box and try to run the app

	vagrant ssh
	...
	vagrant@vagrant-ubuntu-trusty-64:~$ cd /vagrant/
	vagrant@vagrant-ubuntu-trusty-64:~$ rails s
	=> Booting Puma
	=> Rails 4.2.0 application starting in development on http://localhost:3000
	=> Run `rails server -h` for more startup options
	=> Ctrl-C to shutdown server
	Puma 2.11.2 starting...
	* Min threads: 0, max threads: 16
	* Environment: development
	* Listening on tcp://localhost:3000

Now when you enter `http://localhost:4567` in your host browser everything should be up and running!

# Where to go now?

* Creating a production environment with multiple users, better nginx configuration etc.
* Integrating with automated deployment (Cap)
* Using ready cookbooks from Berkshelf or Librarian Chef and uploading your cookbooks to their repositories
* Managing more than 1 node :)
username = node['user']['name']

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

  #not_if { File.exists?("/home/#{username}/.rvm/VERSION") && `cat /home/#{username}/.rvm/VERSION`.start_with?(node['rvm']['version']) }
end
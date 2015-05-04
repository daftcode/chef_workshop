#
# Cookbook Name:: my_rails_app
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

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
#
# Cookbook Name:: razor
# Recipe:: server
#
# Copyright 2014, Western University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'uri'

include_recipe "postgresql::server"
include_recipe "database::postgresql"
include_recipe 'torquebox::server'
include_recipe 'nginx'

current_version_dir = File.join(node[:razor][:install_dir], node[:razor][:current_version_link])
microkernel_tarball = File.join(Chef::Config[:file_cache_path],"razor-microkernel-latest.tar")
dist_file = "razor-server-#{node[:razor][:version]}.zip"
extracted_dir = "razor-#{node[:razor][:version]}"
basic_auth_encoded = Base64.strict_encode64("#{node[:razor][:admin_user]}:#{node[:razor][:admin_password]}")

node[:razor][:packages].each do |pkg|
  package pkg do
    action :install
  end
end

service 'torquebox' do
  action   :start
end

################################################################################
# Razor database configuration                                                 #
################################################################################

postgresql_connection_info = {
  :host     => '127.0.0.1',
  :port     => node['postgresql']['config']['port'],
  :username => 'postgres',
  :password => node['postgresql']['password']['postgres']
}

# create a postgresql database
postgresql_database node[:razor][:database][:name] do
  connection(
    :host      => '127.0.0.1',
    :port      => 5432,
    :username  => 'postgres',
    :password  => node['postgresql']['password']['postgres']
  )
  action :create
end

postgresql_database_user node[:razor][:database][:user] do
  connection postgresql_connection_info
  password   node[:razor][:database][:password]
  action     :create
end

postgresql_database_user node[:razor][:database][:user] do
  connection    postgresql_connection_info
  database_name node[:razor][:database][:name]
  privileges    [:all]
  action        :grant
end

################################################################################
# Nginx reverse proxy configuration                                            #
################################################################################

file File.join(node['nginx']['dir'], 'conf.d', 'default.conf') do
  action :delete
  notifies :restart, 'service[nginx]'
end

template File.join(node['nginx']['dir'], 'sites-available', 'razor') do
  source 'razor.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  notifies :restart, 'service[nginx]'
end

nginx_site 'default' do
  enable false
end

nginx_site 'razor' do
  enable true
  timing :immediately
end

################################################################################
# Razor installation                                                           #
################################################################################

directory node[:razor][:repo_store_dir] do
  owner     node[:torquebox][:jboss][:user]
  mode      '0755'
  recursive true
  action :create
end

remote_file microkernel_tarball do
  source node[:razor][:microkernel_url]
  owner  "root"
  group  "root"
  mode   "0644"
  action :create
  notifies :run, "bash[extract razor microkernel]", :immediately
end

bash 'extract razor microkernel' do
  user   'root'
  cwd    node[:razor][:repo_store_dir]
  code   "tar xvf #{microkernel_tarball}"
  action :nothing
end

directory node[:razor][:install_dir] do
  owner     'root'
  group     'root'
  mode      '0755'
  recursive true
  action    :create
end

log 'switch razor version' do
  message "Installing razor version #{node[:razor][:version]}"
  only_if { ! (File.exist?(current_version_dir) && File.readlink(current_version_dir) =~ /razor-#{node[:razor][:version]}/) }

  notifies :create_if_missing, 'remote_file[razor package]', :immediately
  notifies :create, "directory[razor dir]", :immediately
  notifies :run, "bash[extract razor]", :immediately
end

remote_file 'razor package' do
  source   node[:razor][:dist_url]
  path     File.join(node[:razor][:install_dir], dist_file)
  action   :nothing
end

directory "razor dir" do
  path    File.join(node[:razor][:install_dir], extracted_dir)
  owner   'root'
  group   'root'
  mode    '0755'
  action  :nothing
end

bash 'extract razor' do
  user   'root'
  cwd    File.join(node[:razor][:install_dir], extracted_dir)
  code   "unzip -o #{File.join(node[:razor][:install_dir], dist_file)}"
  action :nothing
end

template 'razor config' do
  path     File.join(node[:razor][:install_dir], extracted_dir, 'config.yaml')
  source   'config.yaml.erb'
  owner    'root'
  group    'torquebox'
  mode     '0640'
  action   :create
  notifies :run, "bash[migrate razor database]", :immediately
end

link 'razor current directory' do
  target_file File.join(node[:razor][:install_dir], node[:razor][:current_version_link])
  to          File.join(node[:razor][:install_dir], extracted_dir)
end

bash 'migrate razor database' do
  user   'root'
  cwd    File.join(node[:razor][:install_dir], extracted_dir)
  environment({
    'TORQUEBOX_HOME' => node[:torquebox][:home],
    'JBOSS_HOME'     => node[:torquebox][:jboss][:home],
    'JRUBY_HOME'     => node[:torquebox][:jruby][:home]
  })
  code "#{node[:torquebox][:jruby][:command]} bin/razor-admin -e production migrate-database"
  action :nothing
end

torquebox_application 'razor-server' do
  root     File.join(node[:razor][:install_dir], extracted_dir)
  env      'production'
  action   :deploy
end

################################################################################
# Torquebox authentication                                                     #
################################################################################

remote_file File.join(node[:razor][:install_dir], File.basename(URI(node[:razor][:shiro_tools_hasher_url]).path)) do
  source node[:razor][:shiro_tools_hasher_url]
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
end

template File.join(current_version_dir, 'shiro.ini') do
  source 'shiro.ini.erb'
  owner  'torquebox'
  group  'root'
  mode   '0440'
  action :create
  notifies :restart, 'service[torquebox]', :immediately
end

################################################################################
# PXE configuration                                                            #
################################################################################

directory '/var/lib/tftpboot' do
  owner     'root'
  group     'root'
  mode      '0755'
  recursive true
  action    :create
end

remote_file '/var/lib/tftpboot/undionly.kpxe' do
  source node[:razor][:undionly_url]
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
end

# Need to wait for the Razor API to respond so we can download bootstrap.ipxe from it.

ruby_block 'wait for razor to start' do
  block do
    require 'open-uri'

    success = false

    30.downto(1) do |i|
    
      Chef::Log.info("Waiting up to #{i} second(s) for the Razor API to respond...")
      Chef::Log.info(node[:razor][:bootstrap_url])

      begin
        open(node[:razor][:bootstrap_url], :http_basic_authentication=>[node[:razor][:admin_user], node[:razor][:admin_password]]) {}
        success = true
        break
      rescue => ex
        Chef::Log.warn(ex.to_s)
      end

      sleep 1
    end

    if ! success
      raise "Timed out waiting for Razor server to start"
    end

  end

  notifies :create, 'remote_file[/var/lib/tftpboot/bootstrap.ipxe]', :immediately
end


remote_file "/var/lib/tftpboot/bootstrap.ipxe" do
  source              node[:razor][:bootstrap_url]
  owner               'root'
  group               'root'
  mode                '0644'
  use_conditional_get false
  headers({
    'Authorization' => "Basic #{basic_auth_encoded}"
  })
  action              :nothing
end

template '/etc/dnsmasq.conf' do
  source 'dnsmasq.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  notifies :restart, 'service[dnsmasq]', :delayed
end

directory '/etc/dnsmasq.d' do
  owner   'root'
  group   'root'
  mode    '0755'
  action  :create
end

template '/etc/dnsmasq.d/10-dhcp.conf' do
  source 'dhcp.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  notifies :restart, 'service[dnsmasq]', :delayed
end

service 'dnsmasq' do
  supports :status => true, :restart => true, :reload => true
  action   [ :enable, :start ]
end



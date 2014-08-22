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

include_attribute "postgresql"
include_attribute "torquebox::server"

################################################################################
# Parameters you may want to customize                                         #
################################################################################

default[:razor][:version] = '0.15.0'
default[:razor][:dist_url] = 'http://links.puppetlabs.com/razor-server-latest.zip'

# Razor 0.15.0 requires Torquebox 3.0.1
override[:torquebox][:version] = '3.0.1'

default[:razor][:microkernel_url] = 'http://links.puppetlabs.com/razor-microkernel-latest.tar'
default[:razor][:undionly_url] = 'http://boot.ipxe.org/undionly.kpxe'

# Username and password of a unprivileged user that is used to download bootstrap.ipxe from the
# Razor server into the TFTP root.  These should match up with one of the users defined in node[:razor][:api_users].
# The password must be in cleartext here.  Note that this cookbook gives no permissions to the API to this user.  It
# can really only download bootstrap.ipxe.
default[:razor][:bootstrap_user] = 'bootstrap'
default[:razor][:bootstrap_password] = 'razor'

default[:razor][:nic_max] = 4
default[:razor][:bootstrap_hostname] = node[:fqdn]
default[:razor][:bootstrap_ipxe_url] = "tftp://#{node[:razor][:bootstrap_hostname]}/bootstrap.ipxe"
default[:razor][:bootstrap_url] = "http://#{node[:razor][:bootstrap_hostname]}/api/microkernel/bootstrap?nic_max=#{node[:razor][:nic_max]}"

default[:razor][:enable_ssl] = false
default[:razor][:ssl_key] = nil
default[:razor][:ssl_cert] = nil

# Password for the 'razor' database user.  Be sure to change this.
default[:razor][:database][:password] = 'razor'

# Credentials for users allowed to access the Razor API.  Passwords must be hashed/salted
# using the shiro-tools-hasher JAR (which is written to node[:razor][:install_dir])
#
# java -jar /opt/razor/shiro-tools-hasher-1.2.3-cli.jar -p
#
# Note that node[:razor][:bootstrap_user] must exist in this array and should contain the 
# hashed version of node[:razor][:bootstrap_password].  This user will not be assigned to any
# roles.
#
# All other users defined in this array will be given admin privileges to the API.
default[:razor][:api_users] = [
  # bootstrap / razor
  { username: 'bootstrap', password: '$shiro1$SHA-256$500000$7p4TipHWV1BeqKDdOk3u1A==$Qt/0TXCc2jAoiSKZqj6VA9uAZhidEASiL9B69oEvh8Q=' }
]

# Networks to which we want to serve as a DHCP server (i.e. IP address and boot parameters).
# 
# Format:
# [
#   { start_ip: '172.16.0.100', end_ip: '172.16.0.200', netmask: '255.255.255.0', lease: '12h' },
#   { start_ip: '192.168.1.10', end_ip: '192.168.1.50', netmask: '255.255.255.0', lease: '12h' },
#   .
#   .
#   .
# ]

default[:razor][:dhcp] = []

# Networks to which we want to server as a proxyDHCP server (i.e. boot parameters only).
#
# Format:
# [
#   { network: '172.16.10.0', netmask: '255.255.252.0' },
#   { network: '10.100.0.0', netmask: '255.255.0.0' }
# ]

default[:razor][:proxydhcp] = []

default[:razor][:ignore_unknown_macs] = false

################################################################################
# General parameters -- you likely do not need to change these.                #
################################################################################

default[:razor][:install_dir] = '/opt/razor'
default[:razor][:repo_store_dir] = '/var/lib/razor/repo-store'
default[:razor][:current_version_link] = 'current'
default[:razor][:database][:name] = 'razor'
default[:razor][:database][:user] = 'razor'

# URL of the shiro-tools-hasher JAR.  This is used for generating passwords for
# shiro.ini, to lock down the Razor server API.
default[:razor][:shiro_tools_hasher_url] = "http://repo1.maven.org/maven2/org/apache/shiro/tools/shiro-tools-hasher/1.2.3/shiro-tools-hasher-1.2.3-cli.jar"

# Platform-specific packages that are required by Razor.
default[:razor][:packages] = value_for_platform(
  ["centos"] => {
    "default" => ["libarchive", "libarchive-devel", "ipmitool", "dnsmasq"]
  },
  ["ubuntu"] => {
    "default" => ["libarchive13", "libarchive-dev", "ipmitool", "dnsmasq"]
  }
)

################################################################################
# postgresql overrides (Razor is not compatible with v8.4, which is the        #
# default version installed by the postgresql cookbook on CentOS).             #
################################################################################

case node['platform']

when "redhat", "centos", "scientific", "oracle"

  default[:postgresql][:enable_pgdg_yum] = true
  default['postgresql']['version'] = "9.2"
  default['postgresql']['dir'] = "/var/lib/pgsql/data"
  default['postgresql']['client']['packages'] = ["postgresql#{node['postgresql']['version'].split('.').join}-devel"]
  default['postgresql']['server']['packages'] = ["postgresql#{node['postgresql']['version'].split('.').join}-server"]
  default['postgresql']['contrib']['packages'] = ["postgresql#{node['postgresql']['version'].split('.').join}-contrib"]
  default['postgresql']['dir'] = "/var/lib/pgsql/#{node['postgresql']['version']}/data"
  default['postgresql']['server']['service_name'] = "postgresql-#{node['postgresql']['version']}"
  
end


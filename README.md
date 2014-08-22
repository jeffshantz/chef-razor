# chef-razor

Chef cookbook to install / configure a Razor server on a node.

## Supported Platforms

* CentOS (tested on 6.5)
* Ubuntu (tested on 14.04)

## Dependencies

This cookbook depends on the following cookbooks:

* `certificate`
* `database`
* `nginx`
* `postgresql`
* `torquebox` (https://github.com/jeffshantz/chef-torquebox)

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>node[:razor][:version]</tt></td>
    <td>String</td>
    <td>Version of Razor server to install.  Changing this triggers an upgrade/downgrade.</td>
    <td><tt>0.15.0</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:dist_url]</tt></td>
    <td>String</td>
    <td>URL of the Razor server zip file</td>
    <td><tt>http://links.puppetlabs.com/razor-server-latest.zip</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:microkernel_url]</tt></td>
    <td>String</td>
    <td>URL of the Razor microkernel</td>
    <td><tt>http://links.puppetlabs.com/razor-microkernel-latest.tar</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:undionly_url]</tt></td>
    <td>String</td>
    <td>URL of the UNDI driver</td>
    <td><tt>http://boot.ipxe.org/undionly.kpxe</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:bootstrap_user]</tt></td>
    <td>String</td>
    <td>Username of an unprivileged user that will be used to download bootstrap.ipxe during cookbook installation.  <strong>Note:</strong> This user/password must be present in <tt>node[:razor][:api_users]</tt>.</td>
    <td><tt>bootstrap</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:bootstrap_password]</tt></td>
    <td>String</td>
    <td>Password of an unprivileged user that will be used to download bootstrap.ipxe during cookbook installation.  This attribute must contain the password in cleartext.  Note that this cookbook assigns this user <strong>no</strong> permissions to the API -- it can really only download bootstrap.ipxe. <strong>Note:</strong> This user/password must be present in <tt>node[:razor][:api_users]</tt>.</td>
    <td><tt>razor</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:nic_max]</tt></td>
    <td>Integer</td>
    <td>The number of NICs for which MAC addresses will be reported back to the server by <tt>bootstrap.ipxe</tt>.  This is used in determining node identity.  See https://github.com/puppetlabs/razor-server/wiki/Node-identity </td>
    <td><tt>4</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:bootstrap_hostname]</tt></td>
    <td>String</td>
    <td>Hostname to use in the bootstrap URL that new Razor-booted nodes will call.</td>
    <td><tt>node[:fqdn]</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:bootstrap_url]</tt></td>
    <td>String</td>
    <td>Bootstrap URL that new Razor-booted nodes will call.</td>
    <td><tt>http://#{node[:razor][:bootstrap_hostname]}/api/microkernel/bootstrap?nic_max=#{node[:razor][:nic_max]}</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:enable_ssl]</tt></td>
    <td>Boolean</td>
    <td>Whether or not to enable SSL proxying for the Razor server.</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:ssl_key]</tt></td>
    <td>String</td>
    <td>Path to the SSL key file on the server.  It is assumed you will have pre-installed this, perhaps using the <tt>certificate</tt> cookbook.</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:ssl_cert]</tt></td>
    <td>String</td>
    <td>Path to the SSL certificate file on the server.  It is assumed you will have pre-installed this, perhaps using the <tt>certificate</tt> cookbook.</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:database][:password]</tt></td>
    <td>String</td>
    <td>Password for the <tt>razor</tt> database user.</td>
    <td><tt>razor</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:api_users]</tt></td>
    <td>Array of hashes</td>
    <td>
      <p>Credentials for users allowed to access the Razor API.  Passwords must be hashed/salted using the <tt>shiro-tools-hasher</tt> JAR.  The cookbook writes this to <tt>node[:razor][:install_dir]</tt>, or you can download it yourself on your own system.</p>
      <p>Note that <tt>node[:razor][:bootstrap_user]</tt> must exist in this array and should contain the 
         hashed version of <tt>node[:razor][:bootstrap_password]</tt>.  This user will not be assigned to any
         roles.
      </p>
      <p><strong>All other users defined in this array will be given admin privileges to the API.</strong></p>
    </td>
    <td><tt>[ { username: 'bootstrap', password: '$shiro1$SHA-256$500000$7p4TipHWV1BeqKDdOk3u1A==$Qt/0TXCc2jAoiSKZqj6VA9uAZhidEASiL9B69oEvh8Q=' } ]  # bootstrap / razor</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:dhcp]</tt></td>
    <td>Array of hashes</td>
    <td>Networks to which we want to server as a DHCP server (i.e. both IP and boot parameters).  Should be in the form: <tt>[ { start_ip: '172.16.0.100', end_ip: '172.16.0.200', netmask: '255.255.255.0', lease: '12h' } ]</tt></td>
    <td><tt>[]</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:proxydhcp]</tt></td>
    <td>Array of hashes</td>
    <td>Networks to which we want to serve as a proxyDHCP server (i.e. boot parameters only).  This is useful when there is already an authoritative DHCP server running on the network.  Should be in the form: <tt>[ { network: '172.16.10.0', netmask: '255.255.252.0' } ]</tt></td>
    <td><tt>[]</tt></td>
  </tr>
  <tr>
    <td><tt>node[:razor][:ignore_unknown_macs]</tt></td>
    <td>Boolean</td>
    <td>
      <p>Whether or not to ignore requests from unknown MAC addresses.  Razor handles this, so it should not really be necessary, but it avoids having an unknown node boot into the Razor microkernel.</p>
      <p>If you enable this, you'll need to create a configuration file in <tt>/etc/dnsmasq.d</tt> listing all known nodes.  You can use any tags you like.  For example, you might create a file <tt>/etc/dnsmasq.d/nodes.conf:</p>
      <pre><code>dhcp-host=82:de:80:ff:91:78,set:staff
dhcp-host=82:de:80:ff:12:4b,set:manager
dhcp-host=82:de:80:ff:96:39,set:staff</code></pre>
    </td>
    <td><tt>false</tt></td>
  </tr>

</table>

## Usage

### razor::default

Include `razor` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[razor::server]"
  ]
}
```

A sample set of attributes is shown below:

```json
{
  "default_attributes": {
    "razor": {
      "bootstrap_url": "http://hostname.example.com/api/microkernel/bootstrap?nic_max=4",
      "enable_ssl": true,
      "ssl_cert": "/etc/ssl/certs/hostname.example.com.pem",
      "ssl_key": "/etc/ssl/private/hostname.example.com.key",
      "dhcp": [
        { "start_ip": "172.16.0.100", "end_ip": "172.16.0.200", "netmask": "255.255.255.0", "lease": "12h" }
      ],
      "proxydhcp": [
        { "network": "192.16.0.0", "netmask": "255.255.252.0" },
        { "network": "10.50.0.0", "netmask": "255.255.0.0" },
      ]
    }
  }
}
```

Here, we are running a DHCP server on the network 172.16.0.0/24, and a proxyDHCP server on the networks 192.16.0.0/22 and 10.50.0.0/16.  We have also enabled SSL and are specifying the paths to the SSL certificate and key that already exist on the server (presumably installed by the <tt>certificate</tt> cookbook).

Testing

TODO!

To test this with Vagrant, you'll need to generate a secret:

```
openssl rand -base64 512 > test/integration/default/fake-secret
knife data bag create certificates test --secret-file test/integration/default/fake-secret
mkdir -p test/integration/default/data_bags/certificates
knife data bag show certificates test -Fj > test/integration/default/data_bags/certificates/test.json
```

Note: if you get a decryption error, comment out the `knife[:secret_file]` setting in your 
.chef/knife.rb.  When you don't specify a secret file, it's trying to decrypt using your
real secret file, so you get an error.

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (i.e. `add-new-recipe`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request

## License and Authors

Author:: Jeff Shantz (<jeff@csd.uwo.ca>)

```text
Copyright:: 2014, Western University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

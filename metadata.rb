name             'razor'
maintainer       'Jeff Shantz'
maintainer_email 'jeff@csd.uwo.ca'
license          'All rights reserved'
description      'Installs/configures razor (https://github.com/puppetlabs/razor-server)'
long_description 'Installs/Configures razor (https://github.com/puppetlabs/razor-server)'
version          '0.1.0'

supports 'centos'
supports 'ubuntu'

depends 'database'
depends 'postgresql', '~> 3.4.2'
depends 'java'
depends 'nginx', '~> 2.7.4'
depends 'torquebox', '~> 0.1.0'


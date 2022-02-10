# @summary Example usage for a single LXD node
#
# This class represents your profile, where the module will be used.
#
class myprofile { # lint:ignore:autoloader_layout
  class {'lxd':
    ensure                      => present,
    auto_update_interval        => 6,
    auto_update_interval_ensure => present,
    core_https_addres           => '192.168.0.100:8443',
    core_https_address_ensure   => present,
    core_trust_password         => 'sekret',
    core_trust_password_ensure  => present,
    lxd_package_provider        => 'snap',
    manage_snapd                => true
  }

  lxd::storage { 'default':
    driver => 'dir',
    config => {
      'source' => '/var/lib/lxd/storage-pools/default'
    }
  }

  lxd::profile { 'exampleprofile':
    ensure  => 'present',
    config  => {
      'environment.http_proxy' => '',
      'limits.memory'          => '2GB',
    },
    devices => {
      'root' => {
        'path' => '/',
        'pool' => 'default',
        'type' => 'disk',
      },
      'eth0' => {
        'nictype' => 'bridged',
        'parent'  => 'br0',
        'type'    => 'nic',
      }
    }
  }

  lxd::image { 'ubuntu1804':
    ensure      => 'present',
    repo_url    => 'http://example.net/lxd-images/',
    image_file  => 'ubuntu1804.tar.gz',
    image_alias => 'ubuntu1804',
  }

  lxd::instance { 'container01':
    state    => 'started',
    type     => 'container',
    config   => {
      'user.somecustomconfig' => 'My awesome custom env variable',
    },
    profiles => ['exampleprofile'],
    image    => 'ubuntu1804',
    devices  => {
      'log'       => {
        'path'   => '/var/log/',
        'source' => '/srv/log01',
        'type'   => 'disk',
      },
      'bluestore' => {
        'path'   => '/dev/bluestore',
        'source' => '/dev/sdb1',
        'type'   => 'unix-block',
      }
    }
  }
}

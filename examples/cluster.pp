# @summary Example setup of an LXD cluster
#
#
node 'member01' {
  class { 'lxd':
    ensure                     => present,
    core_https_address         => '192.168.0.10:8443',
    core_https_address_ensure  => present,
    core_trust_password        => 'sekret',
    core_trust_password_ensure => present,
    cluster_enable             => true,
    cluster_member_name        => 'member01',
    cluster_trust_password     => 'sekret',
    cluster_join_member        => '192.168.0.10:8443',
    cluster_members            => {
      'member01' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.10:8443'
      },
      'member02' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.11:8443'
      },
      'member03' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.12:8443'
      }
    }
  }

  lxd::storage { 'default':
    ensure => present,
    driver => 'dir',
    config => {}
  }

  lxd::profile { 'example-profile':
    ensure  => present,
    config  => {},
    devices => {
      'root' => {
        'path' => '/',
        'pool' => 'default',
        'type' => 'disk'
      }
    }
  }

  lxd::image { 'ubuntu:focal:amd64:cloud:container':
    ensure => present
  }

  lxd::image { 'ubuntu:focal:amd64:cloud:virtual-machine':
    ensure => present
  }

  lxd::instance { 'container01':
    ensure   => present,
    type     => 'container',
    state    => 'started',
    config   => {},
    profiles => ['example-profile'],
    image    => 'ubuntu:focal:amd64:cloud:container',
    devices  => {}
  }
}

node 'member02' {
  class { 'lxd':
    ensure                     => present,
    core_https_address         => '192.168.0.11:8443',
    core_https_address_ensure  => present,
    core_trust_password        => 'sekret',
    core_trust_password_ensure => present,
    cluster_enable             => true,
    cluster_member_name        => 'member02',
    cluster_trust_password     => 'sekret',
    cluster_join_member        => '192.168.0.11:8443',
    cluster_members            => {
      'member01' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.10:8443'
      },
      'member02' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.11:8443'
      },
      'member03' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.12:8443'
      }
    }
  }

  # Storage from `member01` will be created by LXD
  # when this node joins the cluster

  # Profile from `member02` will be created by LXD
  # when this node joins the cluster

  # Images are synced between LXD cluster node members
}

node 'member03' {
  class { 'lxd':
    ensure                     => present,
    core_https_address         => '192.168.0.12:8443',
    core_https_address_ensure  => present,
    core_trust_password        => 'sekret',
    core_trust_password_ensure => present,
    cluster_enable             => true,
    cluster_member_name        => 'member03',
    cluster_trust_password     => 'sekret',
    cluster_join_member        => '192.168.0.12:8443',
    cluster_members            => {
      'member01' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.10:8443'
      },
      'member02' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.11:8443'
      },
      'member03' => {
        'ensure'  => 'present',
        'enabled' => true,
        'address' => '192.168.0.12:8443'
      }
    }
  }

  # Storage from `member01` will be created by LXD
  # when this node joins the cluster

  # Profile from `member02` will be created by LXD
  # when this node joins the cluster

  # Images are synced between LXD cluster node members
}

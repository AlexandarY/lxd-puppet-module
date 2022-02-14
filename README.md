Puppet LXD mangament module
===

### Table of Contents
* [Overview](#overview)
* [Module Description](#module-description)
* [Requirements](#requirements)
* [Reference](#reference)
    * [Public classes](#public-classes)
    * [Defines](#defines)
* [Example usage](#example-usage)
* [Known limitations](#known-limitations)
* [Development](#development)


# Overview
This is a Puppet Module which manages the state of LXD on the host including basic LXD daemon configuration, containers, profiles, storage pools.

Project is a fork of the [ovh/lxd-puppet-module](https://github.com/ovh/lxd-puppet-module) module
which appears to not be maintained anymore.

Currently the project is work-in-progress for a `2.0.0` release, so if you plan to use this module
be careful as types & parameters might change.

Details on what changes can be found in [`CHANGELOG.md`](CHANGELOG.md).

# Module Description
This module installs LXD and is able to manage instance states as well as most of container related configuration.

This module adds the following resources defines to Puppet:
 - `lxd::profile`
 - `lxd::image`
 - [`lxd::storage`](docs/storage.md)
 - `lxd::container`
 
# Requirements

This module has been tested on:
 * Ubuntu 14.04 with Puppet 3.7
 * Ubuntu 16.04 with Puppet 3.8
 * Ubuntu 18.04 with Puppet 5.4

It works with LXD versions:  
 * series 2.2X
 * series 3.X

It need the following packages to be installed:
 * `wget`  

It needs the follwing Puppet modules to operate:
 * `stdlib`

# Reference

## Public classes

### lxd 

Init class. Installs LXD itself and provision basic configuration. It also forces correct resource order.  

Check `REFERENCES.md` for description of all parameters and check the `examples/` directory for example usage.

All the params have default values in `params.pp`.

Simple Example:

```
class { 'lxd':
  ensure                      => present,
  auto_update_interval        => 6,
  auto_update_interval_ensure => present,
  core_https_addres           => '192.168.0.10:8443',
  core_https_address_ensure   => present,
  core_trust_password         => 'sekret',
  core_trust_password_ensure  => present,
  lxd_package_provider        => 'snap',
  manage_snapd                => true
}
```

The class also supports setting up a node as either an initial cluster node or join
it to an existing cluster.

Example for initial cluster node setup:

```
class { 'lxd':
  ensure                      => present,
  auto_update_interval        => 6,
  auto_update_interval_ensure => present,
  core_https_addres           => '192.168.0.10:8443',
  core_https_address_ensure   => present,
  core_trust_password         => 'sekret',
  core_trust_password_ensure  => present,
  lxd_package_provider        => 'snap',
  manage_snapd                => true,
  member_name                 => 'member01',
  join_member                 => '192.168.0.10:8443',
  members                     => {
    'member01' => {
        'ensure'  => 'present',
        'address' => '192.168.0.10:8443',
        'enabled' => true
    },
    'member02' => {
        'ensure' => 'present',
        'address' => '192.168.0.11:8443',
        'enabled' => true
    },
    'member03' => {
        'ensure' => 'present',
        'address' => '192.168.0.12:8443',
        'enabled' => true
    }
  }
}
```

When setting up a cluster or joining a cluster, the following vars are most important:

 * `cluster_enable` - if the node is to create/join cluster
 * `member_name` - Each node part of a cluster is indetified by name.
 This is where you can set it.
 * `members` - All members that are part of the cluster, including this node.
 * `join_member` - The initial leader of the cluster. Will be used by new nodes
 to connect and request cluster join.
 * `cluster_trust_password` - Password trusted by all members of a cluster.

See `examples/cluster.pp` for an exact example on how to setup a cluster.

## Defines


### lxd::instance

Define manages the state of the containers and virtual machines.

Params are:
 * `type` - Can either be `container` or `virtual-machine`.
 * `state` - Can either be `started` or `stopped`, defaults to `started`.
 * `ensure` - defaults to present,
 * `profiles` - list of profiles that will be used for the container.
 * `image` - image alias from which the container has to be created,
 * `config` - hash `{}` of config values,
 * `devices` - hash `{}` of devices,

For available config and devices options please please consult [LXD REST API docs](https://github.com/lxc/lxd/blob/master/doc/rest-api.md#10containers)

### lxd::profile

This define creates LXD profiles. It has the following parameters:
 * `ensure` - defaults to present,
 * `config` - config values for the profile,
 * `devices` - devices for the profile.

For the values that can be configuration or devices please consult [LXD REST API docs](https://github.com/lxc/lxd/blob/master/doc/rest-api.md#10profiles)

### lxd::image

This define is responsible for adding images to your LXD daemon. It has two modes in which it can pull the images via:

 * `simplestream`

    This is the default way the `lxc` client pulls the images.
    It will attempt to retrieve the LXD image for both `container` or `vm`
    via the official LXD mirror but it can be also pointed to an
    internal `simplestream` LXD image server.
    The whole processed is handled by a custom type & provider - `lxd_image` -
    that can also be used separately from the puppet define.

    Example:
    ```
    # This will retrieve a container image of the default variant
    # for the Debian Buster release built for amd64.
    lxd::image { 'debian:buster:amd64:default:container':
      ensure   => present,
      repo_url => 'images.linuxcontainers.org'
    }

    # This will retrieve a virtual-machine image of the cloud variant
    # for the Debian Bullseye release built for amd64.
    lxd::image { 'debian:bullseye:amd64:cloud:container':
      ensure   => present,
      repo_url => 'images.linuxcontainers.org'
    }
    ```

 * `custom`

    It is prepared to be used with simple file hosting of images in .tar.gz format.
    Just host your files in a directory on file server reachable through http(s) like:
    `https://images.example.com/lxd-images/`
    
    Overall, this define works by first downloading the image with wget to `/tmp` directory. Then it loads it into LXD with `lxd image import` command.

    Example:
    ```
    lxd::image { 'ubuntu1804':
      ensure      => present,
      pull_via    => 'custom',
      repo_url    => 'http://example.net/lxd-images/',
      image_file  => 'ubuntu1804.tar.gz',
      image_alias => 'ubuntu1804'
    }
    ```

More details on the parameters and examples can be found in `REFERENCES.md`

# Example usage:

```
class mymodule {
 
    class {'::lxd': }
 
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
            'limits.memory' => '2GB',
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
 
    lxd::container { 'container01':
        state   => 'started',
        config  => {
            'user.somecustomconfig' => 'My awesome custom env variable',
        },
        profiles => ['exampleprofile'],
        image   => 'ubuntu1804',
        devices => {
            'data' => {
                'path'   => '/data',
                'source' => '/srv/data01',
                'type'   => 'disk',
            }
        }
    }
}
```

# Known limitations

For the moment known limitations of this module include:
* support for x86_64 container architecture only.

# Development

We welcome contributions through GitHub, bug reports and pull requests are welcome.

## Testing

If you develop new feature please write appropriate tests. To run tests you have to make a link in `spec/fixtures/modules`.

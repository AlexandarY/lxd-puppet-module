#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Manage LXD container
#
# @example Create a new container instance
#   lxd::container { 'container01':
#     ensure        => present,
#     state         => 'started',
#     config        => {
#       'limits.memory' => '2048MB'
#     },
#     profiles      => ['default'],
#     instance_type => 'container'
#   }
#
# @example Create a new virtual-machine instance
#   lxd::container { 'vm01':
#     ensure        => present,
#     state         => 'started',
#     config        => {
#       'limits.memory' => '2048MB'
#     },
#     profiles      => ['default'],
#     instance_type => 'virtual-machine'
#   }
#
# @param ensure
#   Ensure the state of the resource
# @param image
#   Image from which to create the container
# @param config
#   Config values for the container
# @param devices
#   Devices to be attached to container
# @param profiles
#   Profiles to be assigned to container
# @param instance_type
#   Type of instance to be created
# @param state
#   State of the container
#
define lxd::container(
    String                               $image,
    Hash                                 $config        = {},
    Hash                                 $devices       = {},
    Array[String]                        $profiles      = ['default'],
    Enum['container', 'virtual-machine'] $instance_type = 'container',
    Enum['started', 'stopped']           $state         = 'started',
    Enum['present', 'absent']            $ensure        = present,
) {
    # creating lxd container

    lxd_container { $name:
        ensure   => $ensure,
        state    => $state,
        config   => $config,
        devices  => $devices,
        profiles => $profiles,
        image    => $image,
    }

    case $ensure {
        'present': {
            Lxd::Image[$image]
            -> Lxd::Container[$name]
        }
        'absent': {
            Lxd::Container[$name]
            -> Lxd::Image[$image]
        }
        default : {
            fail("Unsuported ensure value ${ensure}")
        }
    }
}

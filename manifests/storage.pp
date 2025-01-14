#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Manage LXD storage pool
#
# @example Simple usage
#   lxd::storage { 'default-storage':
#     ensure => present,
#     driver => 'dir',
#     config => {
#       'rsync.compression' => true,
#     },
#     source => '/opt/data'
#   }
#
# @param ensure
#   Ensure the state of the resource
# @param driver
#   Backend storage driver
# @param config
#   Config values for the storage
# @param description
#   Description of the storage backend
# @param source
#   Path to block device or loop file or filesystem entry
#
define lxd::storage(
  String                    $driver,
  Hash[String, String]      $config      = {},
  String                    $description = 'Managed by Puppet',
  Optional[String]          $source      = undef,
  Enum['present', 'absent'] $ensure      = present,
) {
  lxd_storage { $name:
    ensure      => $ensure,
    driver      => $driver,
    config      => $config,
    source      => $source,
    description => $description,
  }
}

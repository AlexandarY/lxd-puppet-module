#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Performs install actions for LXD
#
# @api private
#
class lxd::install {
  if $lxd::lxd_package_provider == 'deb' {
    package { 'lxd':
      ensure          => $lxd::ensure,
      install_options => $lxd::install_options,
    }
  } else {
    if $lxd::manage_snapd {
      package { 'snapd':
        ensure => $::lxd::ensure,
      }
    }

    if $lxd::ensure == 'present' {
      exec { 'install lxd':
        path    => '/bin:/usr/bin',
        command => '/usr/bin/snap install lxd',
        unless  => '/usr/bin/snap list lxd',
      }
    } else {
      exec { 'remove lxd':
        path    => '/bin:/usr/bin',
        command => '/usr/bin/snap remove lxd',
        unless  => 'test ! /usr/bin/snap list lxd >/dev/null 2>&1',
      }
    }

    # Set order
    # If snapd is managed, ensure the package state before
    # attemptin to install lxd
    if $lxd::ensure == 'present' and $lxd::manage_snapd {
      Package['snapd']
      -> Exec['install lxd']
    }
    # If removing lxd & also managing the snapd package state
    if $lxd::ensure == 'absent' and $lxd::manage_snapd {
      Exec['remove lxd']
      -> Package['snapd']
    }
  }
}

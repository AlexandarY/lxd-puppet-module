#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Manage LXD and its configuration
#
# @param ensure
#   Ensure the state of the resources
# @param version
#   Version to be installed
# @param install_options
#   Additional install options passed to apt eg. `-t trusty-backports`
# @param auto_update_interval_ensure
#   Manage Auto Update Interval
# @param auto_update_interval
#   Default interval to update remote images, 0 to disable
# @param core_https_address_ensure
#   Manage LXD Core HTTPS Address
# @param core_https_address
#   HTTPS address on which LXD to listen to
# @param core_trust_password_ensure
#   Manage LXD default trust password for clustering
# @param core_trust_password
#   LXD trust password for clusters
# @param lxd_package_provider
#   Which package provider should install lxd.
# @param manage_snapd
#   If class should manage install of `snapd`.
#   There might be cases where the package is managed externally
#   and would cause conflict.
#
class lxd(
    Enum['present', 'absent'] $ensure                      = $lxd::params::ensure,
    Optional[String]          $version                     = $lxd::params::version,
    Array[String]             $install_options             = $lxd::params::install_options,
    Integer                   $auto_update_interval        = $lxd::params::auto_update_interval,
    Enum['present', 'absent'] $auto_update_interval_ensure = $lxd::params::auto_update_interval_ensure,
    String                    $core_https_address          = $lxd::params::core_https_address,
    Enum['present', 'absent'] $core_https_address_ensure   = $lxd::params::core_https_address_ensure,
    String                    $core_trust_password         = $lxd::params::core_trust_password,
    Enum['present', 'absent'] $core_trust_password_ensure  = $lxd::params::core_trust_password_ensure,
    Enum['deb', 'snap']       $lxd_package_provider        = $lxd::params::lxd_package_provider,
    Boolean                   $manage_snapd                = $lxd::params::manage_snapd
) inherits lxd::params {
    contain ::lxd::install
    contain ::lxd::config

    Class['lxd::install']
    -> Class['lxd::config']

    # Every container has to be created after LXD is installed, of course
    # Container can have multiple profiles so better make sure that
    # ever profile is created before creating
    Class['::lxd']
    -> Lxd::Storage <| ensure == 'present' |>
    -> Lxd::Profile <| ensure == 'present' |>
    -> Lxd::Container <| ensure == 'present' |>

    Class['::lxd']
    -> Lxd::Container <| ensure == 'absent' |>
    -> Lxd::Profile <| ensure == 'absent' |>
    -> Lxd::Storage <| ensure == 'absent' |>
}

#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Manage LXD and its configuration
#
# @example Single Node setup
#   class {'lxd':
#     ensure                      => present,
#     auto_update_interval        => 6,
#     auto_update_interval_ensure => present,
#     core_https_addres           => '192.168.0.10:8443',
#     core_https_address_ensure   => present,
#     core_trust_password         => 'sekret',
#     core_trust_password_ensure  => present,
#     lxd_package_provider        => 'snap',
#     manage_snapd                => true
#   }
#
# @example Cluster member setup
#   class { 'lxd::cluster':
#     ensure                      => present,
#     auto_update_interval        => 6,
#     auto_update_interval_ensure => present,
#     core_https_addres           => '192.168.0.10:8443',
#     core_https_address_ensure   => present,
#     core_trust_password         => 'sekret',
#     core_trust_password_ensure  => present,
#     lxd_package_provider        => 'snap',
#     manage_snapd                => true,
#     cluster_enable              => true,
#     member_name                 => 'member01',
#     cluster_trust_password      => 'sekret',
#     join_member                 => '192.168.0.10:8443',
#     members                     => {
#       'member01' => {
#         'address' => '192.168.0.10:8443',
#         'enabled' => true
#       },
#       'member02' => {
#         'address' => '192.168.0.10:8443',
#         'enabled' => true
#       },
#       'member03' => {
#         'address' => '192.168.0.12:8443',
#         'enabled' => true
#       }
#     }
#   }
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
# @param cluster_enable
#   Should clustering be enabled for this LXD node.
# @param cluster_member_name
#   Name via which node will be indetified in cluster
# @param cluster_trust_password
#   Cluster trust password
# @param cluster_join_member
#   An existing cluster member that would be reached to perform join.
#   If the memeber being configured matches join_member, then
#   this member is the one forming the cluster.
# @param cluster_members
#   Members that will be part of the cluster
#
class lxd(
    Enum['present', 'absent']    $ensure                      = $lxd::params::ensure,
    Optional[String]             $version                     = $lxd::params::version,
    Array[String]                $install_options             = $lxd::params::install_options,
    Integer                      $auto_update_interval        = $lxd::params::auto_update_interval,
    Enum['present', 'absent']    $auto_update_interval_ensure = $lxd::params::auto_update_interval_ensure,
    String                       $core_https_address          = $lxd::params::core_https_address,
    Enum['present', 'absent']    $core_https_address_ensure   = $lxd::params::core_https_address_ensure,
    String                       $core_trust_password         = $lxd::params::core_trust_password,
    Enum['present', 'absent']    $core_trust_password_ensure  = $lxd::params::core_trust_password_ensure,
    Enum['deb', 'snap']          $lxd_package_provider        = $lxd::params::lxd_package_provider,
    Boolean                      $manage_snapd                = $lxd::params::manage_snapd,
    Boolean                      $cluster_enable              = $lxd::params::cluster_enable,
    Optional[String]             $cluster_member_name         = $lxd::params::cluster_member_name,
    Optional[String]             $cluster_trust_password      = $lxd::params::cluster_trust_password,
    Optional[String]             $cluster_join_member         = $lxd::params::cluster_join_member,
    Optional[Hash[String, Hash]] $cluster_members             = $lxd::params::cluster_members
) inherits lxd::params {
  contain lxd::install
  contain lxd::config

  if $cluster_enable {
    contain lxd::cluster

    Class['lxd::install']
    -> Class['lxd::config']
    -> Class['lxd::cluster']
  } else {
    Class['lxd::install']
    -> Class['lxd::config']
  }

  # Every container has to be created after LXD is installed, of course
  # Container can have multiple profiles so better make sure that
  # ever profile is created before creating
  Class['lxd']
  -> Lxd::Storage <| ensure == 'present' |>
  -> Lxd::Profile <| ensure == 'present' |>
  -> Lxd::Container <| ensure == 'present' |>

  Class['lxd']
  -> Lxd::Container <| ensure == 'absent' |>
  -> Lxd::Profile <| ensure == 'absent' |>
  -> Lxd::Storage <| ensure == 'absent' |>
}

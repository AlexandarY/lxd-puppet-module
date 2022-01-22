# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

Puppet::Type.newtype(:lxd_cluster_member) do
  @doc = "Manage an LXD Cluster member

  @example
    lxd_cluster { 'name-of-member':
      ensure           => present,
      enabled          => true,
      cluster_password => 'sekret',
      address          => '192.168.0.100:8443',
      join_member      => '192.168.0.100:8443',
      other_members    => ['192.168.0.101:8443', '192.168.0.102:8443']
    }
  "

  ensurable

  newparam(:name, :namevar => true) do # rubocop:disable HashSyntax
    desc 'Unique name of cluster'
  end

  newproperty(:enabled) do
    desc 'If the member should be evacuated or restored'
  end

  newparam(:cluster_password) do
    desc 'The trust password of the cluster you are trying to join'
  end

  newparam(:address) do
    desc 'Address for communicating with the other cluster members'
  end

  newparam(:join_member) do
    desc 'Member that will be used for cluster joining'
  end

  newparam(:other_members) do
    desc 'Other members that are part of the cluster'
  end
end

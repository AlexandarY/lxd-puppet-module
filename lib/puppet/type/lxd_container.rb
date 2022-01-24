# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

Puppet::Type.newtype(:lxd_container) do
  desc 'Setting basic LXD configuration'

  ensurable

  newparam(:name, :namevar => true) do # rubocop:disable HashSyntax
    desc 'Unique name of the config container'
  end

  newparam(:image) do
    desc 'Image for container creation'
  end

  newparam(:instance_type) do
    desc 'If instance should be a container or a VM'
  end

  newproperty(:config, :hash_matching => :all) do # rubocop:disable HashSyntax
    desc 'Array of config values'
    validate do |value|
      unless value.is_a? Hash
        raise ArgumentError, "config is #{value.class}, expected Hash"
      end
    end
  end

  newproperty(:devices, :hash_matching => :all) do # rubocop:disable HashSyntax
    desc 'Array of devices'
    validate do |value|
      unless value.is_a? Hash
        raise ArgumentError, "config is #{value.class}, expected Hash"
      end
    end
  end

  newproperty(:state) do
    desc 'State of the container'
  end

  newproperty(:profiles, :array_matching => :all) do # rubocop:disable HashSyntax
    desc 'Profile of the container'
  end
end

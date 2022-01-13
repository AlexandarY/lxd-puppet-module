# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

Puppet::Type.newtype(:lxd_storage) do
  desc 'Setting LXD storage-pools'

  ensurable

  newparam(:name, :namevar => true) do # rubocop:disable HashSyntax
    desc 'Unique name of the profile'
  end

  newproperty(:driver) do
    desc 'Backend storage driver'
  end

  newproperty(:description) do
    desc 'Description of the storage backend'
  end

  newproperty(:config, :hash_matching => :all) do # rubocop:disable HashSyntax
    desc 'Hash of storage config values'
    validate do |value|
      unless value.is_a? Hash
        raise ArgumentError, "config is #{value.class}, expected Hash"
      end
    end
  end
end

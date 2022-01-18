# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

Puppet::Type.newtype(:lxd_image) do
  @doc = "Manage an LXD image

  @example
    lxd_image { 'debian:buster:amd64:default:container':
      ensure   => present,
      repo_url => 'uk.lxd.images.canonical.com'
    }
    lxd_image { 'debian:buster:amd64:default:virtual-machine':
      ensure   => present,
      repo_url => 'custom.lxd.simplestream.server.com'
    }
  "

  ensurable

  newparam(:name, :namevar => true) do # rubocop:disable HashSyntax
    desc 'Unique name of the profile'
  end

  newparam(:repo_url) do
    desc 'Repository for Images'
  end
end

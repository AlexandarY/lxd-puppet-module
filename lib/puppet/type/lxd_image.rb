# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

Puppet::Type.newtype(:lxd_image) do
  @doc = "Manage an LXD image

  @example
    lxd_image { 'debian:buster':
      ensure   => present,
      repo_url => 'uk.lxd.images.canonical.com',
      arch     => 'amd64',
      img_type => 'container',
      variant  => 'default'
    }
  "

  ensurable

  newparam(:name, :namevar => true) do # rubocop:disable HashSyntax
    desc 'Unique name of the profile'
  end

  newparam(:repo_url) do
    desc 'Repository for Images'
  end

  newparam(:arch) do
    desc 'Architecture the image was built for'
    validate do |value|
      unless ['amd64'].include? value
        raise ArgumentError, "#{value} is not a supported architecture!"
      end
    end
  end

  newparam(:img_type) do
    desc 'Type of platform for which the image was built'
    validate do |value|
      unless ['container', 'virtual-machine'].include? value
        raise ArgumentError, "#{value} is not a valid img_type!"
      end
    end
  end

  newparam(:variant) do
    desc 'Image variant'
    validate do |value|
      unless ['default', 'cloud', 'desktop'].include? value
        raise ArgumentError, "#{value} is not a valid option for variant!"
      end
    end
  end
end

#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Manage LXD images
#   It's mandatory that the name is in the following format:
#   <OS>:<release>
#   and that it uses the release name and not release numbers!
#
#   Example: debian:buster | ubuntu:focal
#
# @example Example for retrieving from official image repository
#   lxd::image { 'ubuntu:focal':
#     ensure     => present,
#     repo_url   => 'uk.lxd.images.canonical.com',
#     arch       => 'amd64',
#     image_type => 'container',
#     variant    => 'default',
#   }
#
# @example Example for retrieving multiple variants of same OS Release
#   lxd::image { 'debian:buster:amd64:default':
#     ensure     => present,
#     image_type => 'container',
#     arch       => 'amd64',
#     variant    => 'default'
#   }
#   lxd::image { 'debian:buster:amd64:cloud':
#     ensure     => present,
#     image_type => 'container',
#     arch       => 'amd64',
#     variant    => 'cloud'
#   }
#   lxd::image { 'debian:buster:amd64:cloud:vm':
#     ensure     => present,
#     image_type => 'virtual-machine',
#     arch       => 'amd64',
#     variant    => 'cloud'
#   }
#
# @param ensure
#   Ensure the state of the resource
# @param arch
#   Architecture of the image
# @param image_type
#   If it's an image for container or VM
# @param variant
#   Variant of the Image.
# @param repo_url
#   LXD image mirror URL
# @param pull_from
#   From where the image should be pulled
# @param image_file
#   Name of the image file
# @param image_alias
#   Alias for the image being downloaded
#
define lxd::image(
    Enum['present', 'absent']            $ensure        = present,
    String                               $arch          = 'amd64',
    Enum['container', 'virtual-machine'] $image_type    = 'container',
    Enum['default', 'desktop', 'cloud']  $variant       = 'default',
    String                               $repo_url      = 'uk.lxd.images.canonical.com',
    Enum['official', 'custom']           $pull_from     = 'official',
    Optional[String]                     $image_file    = undef,
    Optional[String]                     $image_alias   = undef
) {
  case $pull_from {
    'official': {
      lxd_image { $name:
        ensure   => $ensure,
        repo_url => $repo_url,
        arch     => $arch,
        img_type => $image_type,
        variant  => $variant
      }
    }
    'custom': {
      validate_re($repo_url, "[^;']+")
      validate_re($image_file, "[^;']+")
      validate_re($image_alias, "[^;']+")

      case $ensure {
        'present': {
          # unfortunately no way to import image from stdin
          exec { "lxd image present ${repo_url}/${image_file}":
            command => "rm -f /tmp/puppet-download-lxd-image && wget -qO - '${repo_url}/${image_file}' > /tmp/puppet-download-lxd-image && lxc image import /tmp/puppet-download-lxd-image --alias '${image_alias}' && rm -f /tmp/puppet-download-lxd-image",  # lint:ignore:140chars
            unless  => "lxc image ls -cl --format csv | grep '^${image_alias}$'",
            timeout => 600,
          }
        }
        'absent': {
          exec { "lxd image absent ${repo_url}/${image_file}":
            command => "lxc image rm '${image_alias}'",
            onlyif  => "lxc image ls -cl --format csv | grep '^${image_alias}$'",
            timeout => 600,
          }
        }
        default: {
          fail("Wrong ensure value: ${ensure}")
        }
      }
    }
    default: {
      fail("Unknown pull_from value - ${pull_from}")
    }
  }
}

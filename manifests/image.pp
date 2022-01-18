#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Manage LXD images
#   Type implements two ways to retrieve images specified via `pull_via` param.
#     * `simplestream` - The official LXD way of retrieving images
#     * `custom`       - It will utilize wget to retrieve a package and `lxc import` it.
#   When used with `simplestream` it's expected that the name of the resource will be
#   in the following format:
#   <OS>:<Release>:<Architecture>:<Variant>:<Type>
#   Example: debian:buster:amd64:default:container
#
# @example Example for retrieving from official image repository
#   lxd::image { 'ubuntu:focal:amd64:default:container':
#     ensure   => present,
#     repo_url => 'images.linuxcontainers.org'
#   }
#
# @example Example for retrieving multiple variants of same OS Release
#   lxd::image { 'debian:buster:amd64:default:container':
#     ensure => present,
#   }
#   lxd::image { 'debian:buster:amd64:cloud:container':
#     ensure => present,
#   }
#   lxd::image { 'debian:buster:amd64:cloud:virtual-machine':
#     ensure => present,
#   }
#
# @example Example with custom image
#   lxd::image { 'ubuntu1804':
#     ensure      => present,
#     pull_via    => 'custom',
#     repo_url    => 'http://example.net/lxd-images/',
#     image_file  => 'ubuntu1804.tar.gz',
#     image_alias => 'ubuntu1804'
#   }
#
# @param ensure
#   Ensure the state of the resource
# @param repo_url
#   LXD image mirror URL
# @param pull_via
#   From where the image should be pulled
# @param image_file
#   Name of the image file
# @param image_alias
#   Alias for the image being downloaded
#
define lxd::image(
    Enum['present', 'absent']            $ensure      = present,
    String                               $repo_url    = 'images.linuxcontainers.org',
    Enum['simplestream', 'custom']       $pull_via    = 'simplestream',
    Optional[String]                     $image_file  = undef,
    Optional[String]                     $image_alias = undef
) {
  case $pull_via {
    'simplestream': {
      lxd_image { $name:
        ensure   => $ensure,
        repo_url => $repo_url
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
      fail("Unknown pull_from value - ${pull_via}")
    }
  }
}

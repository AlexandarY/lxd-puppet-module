# @summary Manage an LXD instance
#
# A description of what this defined type does
#
# @example Create a new container instance
#   lxd::instance { 'ct01':
#     ensure   => present,
#     type     => 'container',
#     image    => 'ubuntu:focal:amd64:default:container',
#     state    => 'started',
#     config   => {
#       'limits.memory' => '2GB'
#     },
#     devices  => {},
#     profiles => ['default']
#   }
#
# @example Create a new VM instance
#   lxd::instance { 'vm01':
#     ensure   => present,
#     type     => 'virtual-machine',
#     image    => 'ubuntu:focal:amd64:default:virtual-machine',
#     state    => 'started',
#     config   => {
#       'limits.memory' => '2GB'
#     },
#     devices  => {},
#     profiles => ['default']
#   }
#
# @param ensure
#   Ensure the state of the resource
# @param type
#   Type of the instance to be created
# @param image
#   Image from which to create the container
# @param state
#   State of the container
# @param config
#   Config values for the container
# @param devices
#   Devices to be attached to container
# @param profiles
#   Profiles to be assigned to container
#
define lxd::instance (
  String                               $image,
  Enum['present', 'absent']            $ensure   = present,
  Enum['container', 'virtual-machine'] $type     = 'container',
  Enum['started', 'stopped']           $state    = 'started',
  Hash[String, String]                 $config   = {},
  Hash[String, String]                 $devices  = {},
  Array[String]                        $profiles = ['default']
) {
  lxd_instance { $name:
    ensure   => $ensure,
    type     => $type,
    state    => $state,
    config   => $config,
    devices  => $devices,
    profiles => $profiles,
    image    => $image
  }

  case $ensure {
    'present': {
      Lxd::Image[$image]
      -> Lxd::Instance[$name]
    }
    'absent': {
      Lxd::Instance[$name]
      -> Lxd::Image[$image]
    }
    default: {
      fail("Unsupported ensure value ${ensure}")
    }
  }
}

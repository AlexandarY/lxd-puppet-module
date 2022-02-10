
Puppet::Type.newtype(:lxd_instance) do
  @doc = "Manage an LXD instance

  @example
    lxd_instance { 'instance01':
      ensure   => present,
      type     => 'container',
      image    => 'ubuntu:focal:amd64:default:container',
      config   => {
        'limits.memory' => '2GB'
      },
      devices  => {},
      state    => 'started',
      profiles => ['default']
    }
  "

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique name of the config container'
  end

  newparam(:type) do
    desc 'If instance should be a container or a VM'
    validate do |value|
      unless ['container', 'virtual-machine'].include? value
        raise ArgumentError, "provided type - #{value} - is not a supported value"
      end
    end
  end

  newparam(:image) do
    desc 'Image used in instance creation'
  end

  newproperty(:config, hash_matching: :all) do
    desc 'Array of config values'
    validate do |value|
      unless value.is_a? Hash
        raise ArgumentError, "config is #{value.class}, expected Hash"
      end
    end
  end

  newproperty(:devices, hash_matching: :all) do
    desc 'Array of devices'
    validate do |value|
      unless value.is_a? Hash
        raise ArgumentError, "config is #{value.class}, expected Hash"
      end
    end
  end

  newproperty(:state) do
    desc 'State of the container'
    validate do |value|
      unless ['started', 'stopped'].include? value
        raise ArgumentError, "provided state - #{value} - is not a supported state"
      end
    end
  end

  newproperty(:profiles, array_matching: :all) do
    desc 'Profiles to apply to the container'
  end
end

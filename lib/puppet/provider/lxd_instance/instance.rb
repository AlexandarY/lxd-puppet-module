
require 'json'

Puppet::Type.type(:lxd_instance).provide(:instance) do
  commands lxc: 'lxc'

  ### Helper methods

  # Retrieve all existing LXD instances
  #
  # @return Array[String] List of existing instances
  def get_all_instances
    begin # rubocop:disable RedundantBegin
      resp = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/instances']))
      resp
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while retreiving lxd instances - #{err}"
    end
  end

  # Retrieve LXD instance by name
  #
  # @param name [String] Name of the instance to be searched for
  # @return [Hash, nil]
  def get_instance(name)
    begin # rubocop:disable RedundantBegin
      JSON.parse(lxc(['query', '--wait', '-X', 'GET', "/1.0/instances/#{name}"]))
    rescue JSON::ParserError
      nil
    end
  end

  # Create an LXD instance
  #
  # @param body [Hash] Data required for create api call
  # @return nil
  def create_instance(body)
    begin # rubocop:disable RedundantBegin
      resp = JSON.parse(lxc(['query', '--wait', '-X', 'POST', '-d', body.to_json, '/1.0/instances']))
      unless resp['status'] == 'Success'
        raise Puppet::Error, "Error while creating instance - #{resp}"
      end
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while running instance creation - #{err}"
    end
  end

  # Update an existing LXD instance
  #
  # @param name [String] Name of the instance to be changed
  # @param body [Hash] Values to be updated on the instance
  # @return nil
  def update_instance(name, body)
    # On success it returns no response
    lxc(['query', '--wait', '-X', 'PATCH', '-d', body.to_json, "/1.0/instances/#{name}"])
  end

  # Change an LXD instance state
  #
  # @param name [String] Name of the instance to be adjusted
  # @param state [String] State the instance to be changed to
  # @return nil
  def change_instance_state(name, state)
    begin # rubocop:disable RedundantBegin
      body = { 'action' => state }
      resp = JSON.parse(lxc(['query', '--wait', '-X', 'PUT', '-d', body.to_json, "/1.0/instances/#{name}/state"]))
      unless resp['status'] == 'Success'
        raise Puppet::Error, "Error while changing state to '#{state}' for instance #{name} - #{resp}"
      end
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while running change instance state - #{err}"
    end
  end

  # Delete an LXD instance
  #
  # @param name [String] Name of the instance to be deleted
  # @return nil
  def delete_instance(name)
    begin # rubocop:disable RedundantBegin
      resp = JSON.parse(lxc(['query', '--wait', '-X', 'DELETE', "/1.0/instances/#{name}"]))
      unless resp['status'] == 'Success'
        raise Puppet::Error, "Error while deleting instance #{name} - #{resp}"
      end
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while deleting instances #{name} - #{err}"
    end
  end

  ### Provider methods

  # checking if the resource exists
  def exists?
    instances = get_all_instances
    instances.join(',').include? resource[:name]
  end

  # ensure absent handling
  def destroy
    if state != 'stopped'
      Puppet.debug("Container #{resource[:name]} is running need to stop it first")
      self.state = 'stopped'
    end
    delete_instance(resource[:name])
  end

  # ensure present handling
  def create
    call_body = {
      'name' => resource[:name],
      'architecture' => 'x86_64',
      'profiles' => resource[:profiles],
      'config' => resource[:config],
      'devices' => resource[:devices],
      'source' => {
        'type' => 'image',
        'alias' => resource[:image],
      },
      'type' => resource[:type]
    }
    create_instance(call_body)
    self.state = resource[:state]
  end

  # getter method for property config
  def config
    container = get_instance(resource[:name])
    if container.nil?
      raise Puppet::Error, "Encountered error while retrieving config for container #{resource[:name]}"
    end

    # Each instance gets additional config values on create that
    # might not be required specifically to be managed.
    # next 3 lines filter them out & return only the ones expected to be managed
    managed_keys = resource[:config].keys
    managed_config_hash = container['config'].select { |key, _value| managed_keys.include?(key) }
    managed_config_hash
  end

  # setter method for property config
  def config=(config_hash)
    update_instance(resource[:name], { 'config' => config_hash })
  end

  # getter method for property config
  def devices
    container = get_instance(resource[:name])
    if container.nil?
      raise Puppet::Error, "Encoutnered error while retrieving devices for container #{resource[:name]}"
    end

    devices_hash = container['devices']
    devices_hash
  end

  # setter method for property config
  def devices=(config_hash)
    update_instance(resource[:name], { 'devices' => config_hash })
  end

  # getter method for property state
  def state
    container = get_instance(resource[:name])
    if container.nil?
      raise Puppet::Error, "Error retrieving instance #{resource[:name]}"
    end

    case container['status']
    when 'Running'
      'started'
    when 'Stopped'
      'stopped'
    else
      Puppet.debug("Unknown state! - #{container_state['status']}")
      false
    end
  end

  # setter method for property state
  def state=(state)
    case state
    when 'stopped'
      action = 'stop'
    when 'started'
      action = 'start'
    else
      Puppet.debug('Unsupported state!')
    end
    change_instance_state(resource[:name], action)
  end

  # getter method for property profiles
  def profiles
    container = get_instance(resource[:name])
    if container.nil?
      raise Puppet::Error, "Error retrieving instance #{resource[:name]}"
    end
    container['profiles']
  end

  # setter method for property profiles
  def profiles=(profiles)
    update_instance(resource[:name], { 'profiles' => profiles })
  end
end

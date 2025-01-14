# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'json'

Puppet::Type.type(:lxd_container).provide(:container) do
  commands :lxc => 'lxc' # rubocop:disable HashSyntax

  ### Helper methods

  # returns correct path to API
  def return_api_path(array)
    "/1.0/#{array.join('/')}"
  end

  # GET call to API that take type, name arguments but can also take more
  def get_api_node(path_array)
    JSON.parse(lxc(['query', '--wait', '-X', 'GET', return_api_path(path_array)]))
  end

  # POST call
  def create_api_node(path_array, values_hash)
    JSON.parse(lxc(['query', '--wait', '-X', 'POST', '-d', "#{values_hash.to_json}", return_api_path(path_array)])) # rubocop:todo RedundantInterpolation
  end

  # PUT call
  def put_api_node(path_array, values_hash)
    JSON.parse(lxc(['query', '--wait', '-X', 'PUT', '-d', "#{values_hash.to_json}", return_api_path(path_array)])) # rubocop:disable RedundantInterpolation
  end

  # PATCH call
  def modify_api_node(path_array, values_hash)
    lxc(['query', '--wait', '-X', 'PATCH', '-d', "#{values_hash.to_json}", return_api_path(path_array)]) # rubocop:disable RedundantInterpolation
    true
  end

  # DELETE call
  def delete_api_node(path_array)
    JSON.parse(lxc(['query', '--wait', '-X', 'DELETE', return_api_path(path_array)]))
  end

  ### Provider methods

  # checking if the resource exists
  def exists?
    containers_array = get_api_node(['containers'])
    containers_array.include? return_api_path(['containers', resource[:name]])
  end

  # ensure absent handling
  def destroy
    if self.state != 'stopped' # rubocop:todo RedundantSelf
      Puppet.debug("Container #{resource[:name]} is running need to stop it first")
      self.state = 'stopped'
    end
    delete_api_node(['containers', resource[:name]])
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
      'type' => resource[:instance_type]
    }
    create_api_node(['containers'], call_body)
    self.state = resource[:state]
  end

  # getter method for property config
  def config
    container_hash = get_api_node(['containers', resource[:name]])
    config_hash = container_hash['config']
    managed_keys = resource[:config].keys
    # this is subhash of all config hash with only managed keys, values
    managed_config_hash = config_hash.select { |key, _value| managed_keys.include?(key) }
    managed_config_hash
  end

  # setter method for property config
  def config=(config_hash)
    modify_api_node(['containers', resource[:name]], { 'config' => config_hash })
  end

  # getter method for property config
  def devices
    container_hash = get_api_node(['containers', resource[:name]])
    devices_hash = container_hash['devices']
    devices_hash
  end

  # setter method for property config
  def devices=(config_hash)
    modify_api_node(['containers', resource[:name]], { 'devices' => config_hash })
  end

  # getter method for property state
  def state
    container_state = get_api_node(['containers', resource[:name], 'state'])
    case container_state['status']
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
    operation = put_api_node(['containers', resource[:name], 'state'], { action: action, timeout: 30 })
    Puppet.debug("Operation: #{operation}")
    if operation['status_code'] == 200
      true
    else
      false
    end
  end

  # getter method for property profiles
  def profiles
    get_api_node(['containers', resource[:name]])['profiles']
  end

  # setter method for property profiles
  def profiles=(profiles)
    modify_api_node(['containers', resource[:name]], { 'profiles' => profiles })
  end
end

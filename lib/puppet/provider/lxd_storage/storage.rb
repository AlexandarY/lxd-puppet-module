# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'json'

Puppet::Type.type(:lxd_storage).provide(:storage) do
  commands lxc: 'lxc'

  ### Helper methods

  # Retrieve all existing storage-pools
  #
  # @return Array[String] names of existing storage pools
  def get_storage_pools
    begin # rubocop:disable RedundantBegin
      response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/storage-pools']))
      response
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while retrieving storage-pools - #{err} - #{response}"
    end
  end

  # Retrieve single storage pool
  #
  # @param name [String] name of the storage pool
  def get_storage_pool(name)
    begin # rubocop:disable RedundantBegin
      response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', "/1.0/storage-pools/#{name}"]))
      response
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while retreiving storage-pool #{name} - #{err} - #{response}"
    end
  end

  # Create a new storage-pool
  #
  # @param request_data [Hash] Data for Storage Pool API request
  # @return [nil]
  def create_storage_pool(request_data)
    lxc(['query', '--wait', '-X', 'POST', '-d', request_data.to_json, '/1.0/storage-pools'])
  end

  # Edit an existing storage-pool
  #
  # @param pool_name [String] Name of the storage-pool to update
  # @param body [Hash] Values to be updated in storage-pool data
  # @return [nil]
  def update_existing_storage_pool(pool_name, body)
    lxc(['query', '--wait', '-X', 'PATCH', '-d', body.to_json, "/1.0/storage-pools/#{pool_name}"])
  end

  # Delete an existing storage-pool
  #
  # @param pool_name [String] name of the pool to be deleted
  # @return [nil]
  def delete_storage_pool(pool_name)
    lxc(['query', '--wait', '-X', 'DELETE', "/1.0/storage-pools/#{pool_name}"])
  end

  ### Provider methods
  def self.instances
    storage_pools = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/storage-pools']))
    storage_pools.each do | pool_url |
      storage_pool = JSON.parse(lxc(['query', '--wait', '-X', 'GET', pool_url]))

      # initializes @property_hash for each storage-pool found
      new(
        :name => storage_pool['name'],
        :driver => storage_pool['driver'],
        :description => storage_pool['description'],
        :config => storage_pool['config']
      )
    end
  end

  # checking if the resource exists
  def exists?
    # if the entry '/storage-pools/somename' is present within array returned from /storage-pools
    # then the storage pool somename exists
    # storage_pools = get_storage_pools
    # storage_pools.join(',').include? resource[:name]
    @property_hash[:ensure] == :present
  end

  # ensure absent handling
  def destroy
    delete_storage_pool(resource[:name])
  end

  # ensure present handling
  def create
    call_body = {
      'name' => resource[:name],
      'driver' => resource[:driver],
      'description' => resource[:description],
      'config' => resource[:config],
    }

    # If source is specified, add it to the create request
    unless resource[:source].empty?
      call_body['config'][:source] = resource[:source]
    end

    create_storage_pool(call_body)
  end

  # getter method for property config
  def config
    # storage_info = get_storage_pool(resource[:name])
    # config_hash = storage_info['config']
    # Remove volatile.initial_source key from config as
    # config_hash.delete('volatile.initial_source')
    # Remove 'source' from config as adjusting it on an
    # existing storage-pool is dangerous
    # config_hash.delete('source')
    # config_hash
    @property_hash[:config]
  end

  # setter method for property config
  def config=(config_hash)
    call_body = {
      'config' => config_hash,
    }
    update_existing_storage_pool(resource[:name], call_body)
  end

  # getter method for property description
  def description
    # response = get_storage_pool(resource[:name])
    # desc = response['description']
    # desc
    @property_hash[:description]
  end

  # setter method for property description
  def description=(desc)
    call_body = {
      'description' => desc
    }
    update_existing_storage_pool(resource[:name], call_body)
  end

  # getter method for property driver
  def driver
    # storage_hash = get_storage_pool(resource[:name])
    # driver = storage_hash['driver']
    # driver
    @property_hash[:driver]
  end

  # setter method for property driver
  def driver=(driver) # rubocop:disable UnusedMethodArgument
    # TODO: throw some exception as modyfing driver is not supported
    raise NotImplementedError, 'You cannot modify driver of already created storage!'
  end
end

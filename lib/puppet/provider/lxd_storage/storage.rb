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
  def self.get_storage_pools
      response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/storage-pools']))
      response
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while parsing storage-pools output - #{err} - #{response}"
  end

  # Retrieve single storage pool
  #
  # @param pool_url [String] URL to retrieve pool data. Example: /1.0/storage-pools/pool-name
  # @return Hash response of API call
  def self.get_storage_pool(pool_url)
    response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', pool_url]))
    response
  rescue JSON::ParserError => err
    raise Puppet::Error, "Error while retreiving storage-pool #{name} - #{err} - #{response}"
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
  def update_storage_pool(pool_name, body)
    lxc(['query', '--wait', '-X', 'PATCH', '-d', body.to_json, "/1.0/storage-pools/#{pool_name}"])
  end

  # Delete an existing storage-pool
  #
  # @param pool_name [String] name of the pool to be deleted
  # @return [nil]
  def delete_storage_pool(pool_name)
    lxc(['query', '--wait', '-X', 'DELETE', "/1.0/storage-pools/#{pool_name}"])
  end

  # Returns a list of system resources (entities) this provider may/can manage.
  def self.instances
    pools = []
    storage_pools = get_storage_pools
    storage_pools.each do | pool_url |
      storage_pool = get_storage_pool(pool_url)

      # initializes @property_hash for each storage-pool found
      pools << new(
        :name => storage_pool['name'],
        :ensure => :present,
        :driver => storage_pool['driver'],
        :description => storage_pool['description'],
        :config => storage_pool['config']
      )
    end
    pools
  end

  # Retrieve all resources
  def self.prefetch(resources)
    storage_pools = instances
    resources.keys.each do | name |
      if provider = storage_pools.find { |pool| pool.name == name }
        resources[name].provider = provider
      end
    end
  end

  # checking if the resource exists
  def exists?
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
    @property_hash[:config]
  end

  # setter method for property config
  def config=(config_hash)
    call_body = {
      'config' => config_hash,
    }
    update_storage_pool(resource[:name], call_body)
  end

  # getter method for property description
  def description
    @property_hash[:description]
  end

  # setter method for property description
  def description=(desc)
    call_body = {
      'description' => desc
    }
    update_storage_pool(resource[:name], call_body)
  end

  # getter method for property driver
  def driver
    @property_hash[:driver]
  end

  # setter method for property driver
  def driver=(driver) # rubocop:disable UnusedMethodArgument
    raise NotImplementedError, 'You cannot modify driver of already created storage!'
  end
end

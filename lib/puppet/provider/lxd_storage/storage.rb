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
  # @param target [String] Optional cluster member name
  # @return [nil]
  def create_storage_pool(request_data, target = nil)
    if target.nil?
      lxc(['query', '--wait', '-X', 'POST', '-d', request_data.to_json, '/1.0/storage-pools'])
    else
      lxc(['query', '--wait', '-X', 'POST', '-d', request_data.to_json, "/1.0/storage-pools?target=#{target}"])
    end
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

      # when setting up storage in a cluster, storage-pool is in Pending state
      # before it gets sets on all nodes.
      if storage_pool['status'] == 'Pending'
        ensure_status = :absent
      else
        ensure_status = :present
      end

      # initializes @property_hash for each storage-pool found
      pools << new(
        :name => storage_pool['name'],
        :ensure => ensure_status,
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

  # Retrieve cluster information
  #
  # @return [Hash] cluster information
  def get_cluster_info
    response = JSON.parse(lxc(['query', '-X', 'GET', '/1.0/cluster']))
    response
  rescue JSON::ParserError => err
    raise Puppet::Error, "Error while parsing cluster info - #{err} - #{response}"
  end

  # Retrieve all cluster members
  #
  # @return [Array<String>] list of URLs to all members
  def get_cluster_members
    response = JSON.parse(lxc(['query', '-X', 'GET', '/1.0/cluster/members']))
    response
  rescue JSON::ParserError => err
    raise Puppet::Error, "Error while parsing cluster member info - #{err} - #{response}"
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

    # Retrieve information about cluster setup
    cluster_info = get_cluster_info
    # If clustering isn't enabled, create storage the standard way
    unless cluster_info['enabled']
      create_storage_pool(call_body)
    else
      # retrieve all cluster members and store only their names
      members = get_cluster_members.collect { |member| member.split('/')[-1] }

      # retrieve all storage-pools and check if the storage-pool is in the list
      # If it is, then it was already initilized on a member node
      # Else it's the first node to set it
      # we do it this way to avoid possible 400 errors that might be returned
      # on a direct storage-pools/<name> API call
      storage_pools = get_storage_pools
      node_pool = storage_pools.filter { |pool| pool.include? resource[:name] }

      # Retrieve details about the storage-pool
      storage_pool = get_storage_pool(node_pool)

      # If it's Pending, but not on this node, run create to put it in
      # Pending state for this cluster member
      if storage_pool['status'] == 'Pending' && !storage_pool['locations'].include? cluster_info['server_name']
        create_storage_pool(call_body, cluster_info['server_name'])
      else
        # It's pending on all members and needs global create to
        # put it in Created state
        create_storage_pool(call_body)
      end
    end
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

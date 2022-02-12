# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'json'

Puppet::Type.type(:lxd_storage).provide(:storage) do
  # When setting up a storage-pool in cluster,
  # the following keys cannot be used during commit Create API call
  # but can be used when setting up per-member storage-pool
  # source: https://github.com/lxc/lxd/blob/master/lxd/db/storage_pools.go#L949
  NODE_SPECIFIC_POOL_CONFIG_KEYS = [
    'size',
    'source',
    'volatile.initial_source',
    'zfs.pool_name',
    'lvm.thinpool_name',
    'lvm.vg_name',
  ].freeze

  commands lxc: 'lxc'

  ### Class methods
  # Returns a list of system resources (entities) this provider may/can manage.
  def self.instances
    pools = []
    storage_pools = get_storage_pools
    storage_pools.each do |pool_url|
      storage_pool = get_storage_pool(pool_url)

      # when setting up storage in a cluster, storage-pool is in Pending state
      # before it gets sets on all nodes.
      ensure_status = if storage_pool['status'] == 'Pending'
                        :absent
                      else
                        :present
                      end

      # initializes @property_hash for each storage-pool found
      pools << new(
        name: storage_pool['name'],
        ensure: ensure_status,
        driver: storage_pool['driver'],
        description: storage_pool['description']
      )
    end
    pools
  end

  # Retrieve all resources
  #
  # @param resources [Hash<{String => Puppet::Resource}>] map from name to resource of resources to prefetch
  def self.prefetch(resources)
    storage_pools = instances
    resources.each_key do |name|
      if provider = storage_pools.find { |pool| pool.name == name } # rubocop:disable AssignmentInCondition
        resources[name].provider = provider
      end
    end
  end

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

  ### Helper methods

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
  def update_storage_pool(pool_name, body, target = nil)
    if target.nil?
      lxc(['query', '--wait', '-X', 'PATCH', '-d', body.to_json, "/1.0/storage-pools/#{pool_name}"])
    else
      lxc(['query', '--wait', '-X', 'PATCH', '-d', body.to_json, "/1.0/storage-pools/#{pool_name}?target=#{target}"])
    end
  end

  # Delete an existing storage-pool
  #
  # @param pool_name [String] name of the pool to be deleted
  # @return [nil]
  def delete_storage_pool(pool_name)
    lxc(['query', '--wait', '-X', 'DELETE', "/1.0/storage-pools/#{pool_name}"])
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
    response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/cluster']))
    response
  rescue JSON::ParserError => err
    raise Puppet::Error, "Error while parsing cluster info - #{err} - #{response}"
  end

  # Retrieve all cluster members
  #
  # @return [Array<String>] list of URLs to all members
  def get_cluster_members
    response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/cluster/members']))
    response
  rescue JSON::ParserError => err
    raise Puppet::Error, "Error while parsing cluster member info - #{err} - #{response}"
  end

  # In cluster setups, API calls per target vs overall commit accept different values for `config`
  # this method filters values that are not meant for target or overcall commit
  #
  # @param config [Hash<String, String>] config data to process
  # @param node_specific [Boolean] if data is meant for per-node setup or final create.
  # @return [Hash<String, String>]
  def prepare_config(config, node_specific = true)
    if node_specific
      # loop over all keys that will be passed on a node specific create API call
      # and remove the ones that are not node specific
      config.each_key do |config_key|
        unless NODE_SPECIFIC_POOL_CONFIG_KEYS.include?(config_key)
          config.delete(config_key)
        end
      end
    else
      # Global commit Create cannot contain specific storage-pool keys
      # if found in the 'config' of the body, remove them
      NODE_SPECIFIC_POOL_CONFIG_KEYS.each do |config_key|
        if config.keys.include? config_key
          config.delete(config_key)
        end
      end
    end
    config
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
      call_body['config']['source'] = resource[:source]
    end

    # Retrieve information about cluster setup
    cluster_info = get_cluster_info
    # If clustering isn't enabled, create storage the standard way
    if !cluster_info['enabled']
      create_storage_pool(call_body)
    else
      # retrieve all storage-pools and check if the storage-pool is in the list
      # If it is, then it was already initilized on a member node
      # Else it's the first node to set it
      # we do it this way to avoid possible 400 errors that might be returned
      # on a direct /1.0/storage-pools/<name> API call
      storage_pools = self.class.get_storage_pools
      node_pool = storage_pools.select { |pool| pool.include? resource[:name] }

      # if array is empty, then the pool is not pending anywhere. do initial create
      if node_pool.empty?
        call_body['config'] = prepare_config(call_body['config'])
        create_storage_pool(call_body, cluster_info['server_name'])
      else
        storage_pool = self.class.get_storage_pool(node_pool.first)

        # If it's Pending, but not on this node, run create to put it in
        # Pending state for this cluster member
        if storage_pool['status'] == 'Pending' && !storage_pool['locations'].include?(cluster_info['server_name'])
          call_body['config'] = prepare_config(call_body['config'])
          create_storage_pool(call_body, cluster_info['server_name'])
        else
          # It's pending on all members and needs global create to
          # put it in Created state
          call_body['config'] = prepare_config(call_body['config'], false)
          create_storage_pool(call_body)
        end
      end
    end
  end

  # getter method for property config
  def config
    cluster = get_cluster_info

    if !cluster['enabled']
      pool_info = self.class.get_storage_pool("/1.0/storage-pools/#{resource[:name]}")
    else
      pool_info = self.class.get_storage_pool("/1.0/storage-pools/#{resource[:name]}?target=#{cluster['server_name']}")
    end
    managed_keys = resource[:config].keys
    config_data = pool_info['config'].select { |key, _value| managed_keys.include?(key) }
    config_data
  end

  # setter method for property config
  def config=(config_hash)
    cluster = get_cluster_info

    if !cluster['enabled']
      update_storage_pool(resource[:name], { 'config' => config_hash })
    else
      config_per_node = prepare_config(config_hash.clone, true)
      config_global = prepare_config(config_hash.clone, false)

      update_storage_pool(resource[:name], { 'config' => config_per_node }, cluster['server_name'])
      update_storage_pool(resource[:name], { 'config' => config_global })
    end
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

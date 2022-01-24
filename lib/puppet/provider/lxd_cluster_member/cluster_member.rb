# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'json'

Puppet::Type.type(:lxd_cluster_member).provide(:cluster_member) do
  commands :lxc => 'lxc' # rubocop:disable HashSyntax

  ### Helper methods

  # Check if current LXD host has cluster enabled
  #
  def part_of_cluster?
    response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/cluster']))

    response['enabled']
  end

  # Retrieve Cluster Cert from existing member
  #
  # @param [String] member - Cluster address of member, from which to get the certificate
  #   Example: 192.168.0.10:8443
  #
  def get_cluster_cert_from_member(member)
    member_addr = member.split(':').first
    member_port = member.split(':').last

    http = Net::HTTP.start(member_addr, member_port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE)

    http.peer_cert.to_pem
  end

  # Initialize a new cluster
  #
  # @param [String] server_address
  #   Address in the format `192.168.0.10:8443` via which the node can be reached in the new cluster
  # @param [String] server_name
  #   Name, via which the member will be recognized in the cluster
  #
  def init_cluster(server_address, server_name)
    params = { 'enabled' => true, 'server_address' => server_address, 'server_name' => server_name }

    begin
      response = JSON.parse(lxc(['query', '--wait', '-X', 'PUT', '--data', params.to_json.to_s, '/1.0/cluster']))

      raise Puppet::Error, "Error on init operation - #{response}" unless response['status'] == 'Success'
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error during cluster init - #{err}"
    end
  end

  # Join an existing cluster
  #
  def join_cluster(join_member, server_address, server_name, cluster_password)
    cluster_cert = get_cluster_cert_from_member(join_member)

    params = {
      'cluster_address' => join_member,
      'cluster_certificate' => cluster_cert,
      'cluster_password' => cluster_password,
      'enabled' => true,
      'server_address' => server_address,
      'server_name' => server_name
    }

    begin
      response = JSON.parse(lxc(['query', '--wait', '-X', 'PUT', '--data', params.to_json.to_s, '/1.0/cluster']))

      raise Puppet::Error, "Error on join operation - #{response}" unless response['status'] == 'Success'
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while attempting to join cluster - #{err.message}"
    end
  end

  # Check if the server is the last member of the cluster
  # If it is, when attempting to leave LXD will throw an error:
  # Error: Member is the only member in the cluster
  #
  def last_member?
    begin # rubocop:todo RedundantBegin
      response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/cluster/members']))

      if response.length > 1
        false
      else
        true
      end
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while checking cluster members - #{err} - #{response}"
    end
  end

  # Leave a cluster
  #
  # @param [String] server_name - Name of the member to remove
  #
  def leave_cluster(server_name)
    response = lxc(['query', '--wait', '-X', 'DELETE', "/1.0/cluster/members/#{server_name}"])

    raise Puppet::Error, "Error encountered while leaving cluster - #{response}" unless response == '\n'
  end

  ### Provider methods

  # checking if the resource exists
  def exists?
    part_of_cluster?
  end

  # ensure present handling
  def create
    if resource[:address] == resource[:join_member]
      init_cluster(resource[:address], resource[:name])
    else
      join_cluster(
        resource[:join_member],
        resource[:address],
        resource[:name],
        resource[:cluster_password],
      )
    end
  end

  # ensure absent handling
  def destroy
    leave_cluster(resource[:name]) unless part_of_cluster? && last_member?
  end

  # handle retrieval of enabled property value
  def enabled
    begin # rubocop:todo RedundantBegin
      response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', "/1.0/cluster/members/#{resource[:name]}"]))

      if response['status'] == 'Evacuated'
        false
      elsif response['status'] == 'Online'
        true
      else
        raise Puppet::Error, "Unknonw lxc cluster node state - #{response}"
      end
    rescue JSON::ParserError => err
      raise Puppet::Error, "Error while retrieving node state - #{err} - #{response}"
    end
  end

  # handle setting enabled property value
  def enabled=(state)
    action = if state
               'restore'
             else
               'evacuate'
             end

    begin
      params = { 'action' => action }
      response = JSON.parse(lxc(
        [
          'query', '--wait', '-X', 'POST', '--data', "#{params.to_json}", # rubocop:todo RedundantInterpolation
          "/1.0/cluster/members/#{resource[:name]}/state"
        ],
      ))
    rescue JSON::ParserError => err
      rase Puppet::Error, "Error setting node state - #{err} - #{response}"
    end
  end
end

# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'json'
require 'net/http'

Puppet::Type.type(:lxd_image).provide(:image) do
  commands :lxc => 'lxc' # rubocop:disable HashSyntax

  ### Helper methods

  # Determine host for image
  # Net::HTTP doesn't auto-handle 302 redirects, so this method will do that
  #
  # @param [String]  uri_str - URI to be tested if it will respond with 302
  # @param [Integer] limit   - Number of attempts to trace 302's before giving up
  #
  def get_host(uri_str, limit = 10)
    raise ArgumentError, 'too many HTTP Redirects' if limit == 0

    response = Net::HTTP.get_response(URI(uri_str))

    case response
    when Net::HTTPRedirection then
      location = response['location']
      Puppet.debug("redirect to #{location}")
      get_host(location, limit - 1)
    else
      response.uri.host
    end
  end

  # Downloads the OS image
  #
  # @param [String] host      - Host from which the image will be retrieved
  # @param [String] url_path  - URL Path to the image to be downloaded
  # @param [String] dest_path - Path to where file where content will be written
  #
  def download_image(host, url_path, destination_path)
    dest_file = File.open(destination_path, 'w+')

    http_client = Net::HTTP.new(host)

    begin
      http_client.request_get(url_path) do |response|
        response.read_body do |segment|
          dest_file.write(segment)
        end
      end
    ensure
      dest_file.close
    end
  end

  # Retrieve full URL path to images to download
  #
  # @param [Array[String]] image_names - Images for which to retrieve paths
  # @param [String]        name        - Name of the image that is being searched
  # @param [String]        arch        - Architecture for which the image was built
  # @param [String]        variant     - Variant of the image
  # @param [String]        host        - Host at which to check for full URL paths
  #
  def get_url_paths(image_names, name, arch, variant, host)
    content = Net::HTTP.get_response(URI.parse("https://#{host}/streams/v1/images.json"))
    content_json = JSON.parse(content.body)

    result = {}
    image_names.each do |image_name|
      _k, values = content_json['products']["#{name}:#{arch}:#{variant}"]['versions'].first
      result[image_name] = {}
      result[image_name]['path'] = values['items'][image_name]['path']
      result[image_name]['sha256'] = values['items'][image_name]['sha256']
    end
    result
  end

  # Import the image in LXD
  #
  # @param Array[String] image      - Image & metadata file to be imported
  # @param String        alias_name - Alias name to set for the image
  #
  def import_image(images, alias_name)
    cmd_import = ['image', 'import'] + images
    begin
      lxc(cmd_import + ['--alias', alias_name])
    rescue => err
      raise Puppet::Error, "Error while importing image - #{err.message}"
    end
  end

  # Check if the image is already imported
  #
  # @param String resource_name - type resource name expected to be set as alias
  #   The name should be in format "<os>:<release>:<arch>:<variant>:<type>"
  #
  def image_exists(resource_name)
    response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/images']))
    response.each do |image_url|
      img_data = JSON.parse(lxc(['query', '--wait', '-X', 'GET', image_url]))

      unless img_data['aliases'].empty?
        img_data['aliases'].each do |alias_data|
          if alias_data['name'] == resource_name
            return true
          end
        end
      end

      cmp_name = "#{img_data['properties']['os']}" \
      ":#{img_data['properties']['release']}" \
      ":#{img_data['properties']['architecture']}" \
      ":#{img_data['properties']['variant']}" \
      ":#{img_data['type']}"

      if cmp_name == resource_name
        return true
      end
    end

    false
  end

  # Retrieve Image fingerprint
  #
  # @param [String] resource_name - Name of the resource for which to retrieve fingerprint
  #
  def get_image_fingerprint(resource_name)
    response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/images']))

    fingerprint = nil

    response.each do |image_url|
      img_data = JSON.parse(lxc(['query', '--wait', '-X', 'GET', image_url]))

      unless img_data['aliases'].empty? # rubocop:disable Next
        img_data['aliases'].each do |alias_data|
          if alias_data['name'] == resource_name
            fingerprint = img_data['fingerprint']
            break
          end
        end
      end
    end

    raise Puppet::Error, "Couldn't find fingerprint for #{resource_name}" if fingerprint.nil?
    fingerprint
  end

  # Delete the image
  #
  # @param [String] image_fingerprint - Fingerprint of the image
  #
  def delete_image(image_fingerprint)
    response = JSON.parse(lxc(['query', '--wait', '-X', 'DELETE', "/1.0/images/#{image_fingerprint}"]))

    raise Puppet::Error, "Unexpected status found - #{response['status']}" unless response['status'] == 'Success'
  end
  ### Provider methods

  # checking if the resource exists
  def exists?
    image_exists(resource[:name])
  end

  # ensure absent handling
  def destroy
    fingerprint = get_image_fingerprint(resource[:name])
    delete_image(fingerprint)
  end

  # ensure present handling
  def create
    name_arr = resource[:name].split(':')
    os_release = name_arr.first(2).join(':')
    arch = name_arr[2]
    variant = name_arr[3]
    host = get_host("https://#{resource[:repo_url]}")

    # 1. check if the image exists
    images = if resource[:name].split(':').last == 'container'
               get_url_paths(['lxd.tar.xz', 'root.squashfs'], os_release, arch, variant, host)
             else
               get_url_paths(['lxd.tar.xz', 'disk.qcow2'], os_release, arch, variant, host)
             end

    # 2. download the images
    images.each do |image_name, image_data|
      download_image(host, "/#{image_data['path']}", "/tmp/#{image_name}")
    end

    # 3. import image
    images_path = images.keys.map { |img_name| '/tmp/' + img_name }
    import_image(images_path, resource[:name])
  end
end

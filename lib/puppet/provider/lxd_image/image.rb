# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'json'
require 'net/http'

Puppet::Type.type(:lxd_image).provide(:image) do
  commands :lxc => 'lxc' # rubocop:disable HashSyntax

  ### Helper methods

  # Downloads the OS image
  #
  # @param [String] url_path  - URL Path to the image to be downloaded
  # @param [String] dest_path - Path to where file where content will be written
  #
  def download_image(url_path, destination_path)
    dest_file = File.open(destination_path, 'w+')

    http_client = Net::HTTP.new(resource[:repo_url])

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
  #
  def get_url_paths(image_names, name)
    # image_names = ['lxd.tar.xz', 'rootfs.squashfs']
    content = Net::HTTP.get_response(URI.parse("https://#{resource[:repo_url]}/meta/simplestreams/v1/images.json"))
    content_json = JSON.parse(content.body)

    result = {}
    image_names.each do |image_name|
      _k, values = content_json['products']["#{name}:#{resource[:arch]}:#{resource[:variant]}"]['versions'].first
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
  # @param String os_name       - os:release name of the image
  # @param String resource_name - type resource name expected to be set as alias
  #
  def image_exists(os_name, resource_name)
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

      if cmp_name == "#{os_name}:#{resource[:arch]}:#{resource[:variant]}:#{resource[:img_type]}"
        return true
      end
    end

    false
  end

  # Retrieve Image fingerprint
  #
  # @param [String] image_alias - Alias set for the image
  #
  def get_image_fingerprint(image_alias)
    response = JSON.parse(lxc(['query', '--wait', '-X', 'GET', '/1.0/images']))

    fingerprint = nil

    response.each do |image_url|
      img_data = JSON.parse(lxc(['query', '--wait', '-X', 'GET', image_url]))

      unless img_data['aliases'].empty? # rubocop:disable Next
        img_data['aliases'].each do |alias_data|
          if alias_data['name'] == image_alias
            fingerprint = img_data['fingerprint']
            break
          end
        end
      end
    end

    raise Puppet::Error, "Couldn't find fingerprint for #{image_alias}" if fingerprint.nil?
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

  # Convert `name` to usable name for provider
  #
  # @param [String] name - Name of the image
  #   Expected:
  #     `os:release`              => Returns `os:release`
  #     `os:release:arch:variant` => Returns `os:release`
  #
  def parse_name(name)
    name_arr = name.split(':')

    if name_arr.length > 2
      name_arr.first(2).join(':')
    else
      name
    end
  end

  # checking if the resource exists
  def exists?
    os_name = parse_name(resource[:name])
    image_exists(os_name, resource[:name])
  end

  # ensure absent handling
  def destroy
    fingerprint = get_image_fingerprint(resource[:name])
    delete_image(fingerprint)
  end

  # ensure present handling
  def create
    name = parse_name(resource[:name])

    # 1. check if the image exists
    images = if resource[:img_type] == 'container'
               get_url_paths(['lxd.tar.xz', 'root.squashfs'], name)
             else
               get_url_paths(['lxd.tar.xz', 'disk.qcow2'], name)
             end

    # 2. download the images
    images.each do |image_name, image_data|
      download_image("/#{image_data['path']}", "/tmp/#{image_name}")
    end

    # 3. import image
    images_path = images.keys.map { |img_name| '/tmp/' + img_name }
    import_image(images_path, resource[:name])
  end
end

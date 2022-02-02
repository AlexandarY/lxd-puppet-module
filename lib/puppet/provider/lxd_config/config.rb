# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

Puppet::Type.type(:lxd_config).provide(:config) do
  commands :lxc => 'lxc' # rubocop:disable HashSyntax

  # custom function that will get config values
  #
  # @param config_array [Array[String]] values to be set
  # @return [String, nil] the current value for `config_array` option
  def get_lxd_config_value(config_array)
    begin
      output = lxc(['config', 'get', config_array].flatten)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Cannot get config with lxc config: #{e.inspect}")
      return nil
    end
    return output.strip if output != "\n"
  end

  # custom function that will set config values
  #
  # @param config_array [Array[String]] values to be set
  # @param config_value [String] the new value to be set for the config options
  def set_lxd_config_value(config_array, config_value)
    begin # rubocop:todo RedundantBegin
      output = lxc(['config', 'set', config_array, config_value].flatten) # rubocop:todo UselessAssignment
      return true # rubocop:todo RedundantReturn
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Cannot get config with lxc config: #{e.inspect}")
    end
  end

  # custom function that will unset config values
  #
  # @param config_array [Array[String]] values to be set
  def unset_lxd_config_value(config_array)
    begin # rubocop:todo RedundantBegin
      output = lxc(['config', 'unset', config_array].flatten!) # rubocop:todo UselessAssignment
      return true # rubocop:todo RedundantReturn
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Cannot unset config with lxc config: #{e.inspect}")
    end
  end

  # Determines if the current value requires change
  # This method is required as some config settings ones set, do not
  # indicate what the value was (core.trust_password) or return as nil (images.auto_update_interval)
  #
  # @param config_name [String] name of the lxc config option to check
  # @param config_value [String] the value to be changed with (if required)
  # @param force [Boolean] if the change is required, even if the value might be the same
  # @return [String] the value for `config_name`
  def should_update?(config_name, config_value, force)
    current_value = get_lxd_config_value(config_name)

    # In some cases `current_value` will be nil, which for logic below
    # would equal .empty? . Adjust it to avoid undef method on nil class
    if current_value.nil?
      current_value = ''
    end

    # when the trust_password is set, it will only return 'true'.
    # this causes a constant set of value
    if config_name.join('').include?('trust_password') && current_value == 'true' && !force
      return config_value
    end

    if config_name.join('').include?('auto_update_interval') && current_value.empty? && !force
      return config_value
    end

    current_value
  end

  # checking if the resource exists
  def exists?
    get_lxd_config_value(resource[:config]) != nil
  end

  # ensure absent handling
  def destroy
    unset_lxd_config_value(resource[:config])
  end

  # ensure present handling
  def create
    set_lxd_config_value(resource[:config], resource[:value])
  end

  # getter method for getting config value
  def value
    should_update?(resource[:config], resource[:value], resource[:force])
  end

  # setter method for setting config value
  def value=(config_value)
    set_lxd_config_value(resource[:config], config_value)
  end
end

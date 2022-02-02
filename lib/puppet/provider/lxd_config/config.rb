# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

Puppet::Type.type(:lxd_config).provide(:config) do
  commands :lxc => 'lxc' # rubocop:disable HashSyntax

  # custom function that will get config values
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
  def set_lxd_config_value(config_array, config_value)
    begin # rubocop:todo RedundantBegin
      output = lxc(['config', 'set', config_array, config_value].flatten) # rubocop:todo UselessAssignment
      return true # rubocop:todo RedundantReturn
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Cannot get config with lxc config: #{e.inspect}")
    end
  end

  # custom function that will unset config values
  def unset_lxd_config_value(config_array)
    begin # rubocop:todo RedundantBegin
      output = lxc(['config', 'unset', config_array].flatten!) # rubocop:todo UselessAssignment
      return true # rubocop:todo RedundantReturn
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Cannot unset config with lxc config: #{e.inspect}")
    end
  end

  def should_update?(config_name, config_value, force)
    current_value = get_lxd_config_value(config_name)

    # when the trust_password is set, it will only return 'true'.
    # this causes a constant set of value
    if config_name.join('').include? 'trust_password' and current_value == 'true' and !force
      return config_value
    end

    if config_name.join('').include? 'auto_update_interval' and current_value.empty? and !force
      return config_value
    end

    return current_value
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

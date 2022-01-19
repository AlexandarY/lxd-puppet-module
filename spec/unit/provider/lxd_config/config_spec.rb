# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_config).provider(:config) do
  before(:each) do
    @resource = Puppet::Type.type(:lxd_config).new(
      # rubocop:disable HashSyntax
      {
        :ensure      => 'present',
        :config_name => 'global_images.auto_update_interval',
        :config      => ['images.auto_update_interval'],
        :value       => 0,
      },
      # rubocop:enable HashSyntax
    )
    @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
  end

  context 'without lxc config' do
    before :each do
      expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return("\n")
    end
    it 'will check for appropriate config' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
    end
  end
  context 'with lxc config' do
    before :each do
      expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return('0')
    end
    it 'will check for appropriate config' do
      expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
    end
  end
  context 'with setting lxc config' do
    before :each do
      expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return("\n")
      expect(described_class).to receive(:lxc).with(['config', 'set', 'images.auto_update_interval', 0]).and_return('')
    end
    it 'will create appropriate config' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
      expect(@provider.create).to be true # rubocop:todo InstanceVariable
    end
  end
end

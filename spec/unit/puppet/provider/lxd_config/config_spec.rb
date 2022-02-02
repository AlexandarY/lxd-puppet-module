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
        :force       => false,
        :value       => 0,
      },
      # rubocop:enable HashSyntax
    )
    @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
  end

  describe '.exists?' do
    context 'when value not existing' do
      before :each do
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return("\n")
      end
      it 'will return false' do
        expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
      end
    end
    context 'when value exists' do
      before :each do
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return('0')
      end
      it 'will return true' do
        expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
      end
    end
  end
  describe '.create' do
    context 'with value not set' do
      before :each do
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return("\n")
        expect(described_class).to receive(:lxc).with(['config', 'set', 'images.auto_update_interval', 0]).and_return('')
      end
      it 'will set is successfully' do
        expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
        expect(@provider.create).to be true # rubocop:todo InstanceVariable
      end
    end
  end
  describe '.destroy' do
    context 'with value set' do
      before :each do
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return("0")
        expect(described_class).to receive(:lxc).with(['config', 'unset', 'images.auto_update_interval']).and_return('')
      end
      it 'will unset is successfully' do
        expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
        expect(@provider.destroy).to be true # rubocop:todo InstanceVariable
      end
    end
  end
  describe '.value' do
    context 'with value set' do
      before(:each) do
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return('0')
      end
      it 'will return expected value' do
        expect(@provider.value).to eq '0'
      end
    end
    context 'when value is to be set' do
      before(:each) do
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return('6')
        expect(described_class).to receive(:lxc).with(['config', 'set', 'images.auto_update_interval', 0]).and_return('')
      end
      it 'will change successfully' do
        expect(@provider.value).to eq '6'
        expect(@provider.value=0).to eq 0
      end
    end
    context 'when value is different, but should not change' do
      before(:each) do
        @resource = Puppet::Type.type(:lxd_config).new(
          # rubocop:disable HashSyntax
          {
            :ensure      => 'present',
            :config_name => 'global_images.auto_update_interval',
            :config      => ['images.auto_update_interval'],
            :force       => false,
            :value       => 6,
          },
          # rubocop:enable HashSyntax
        )
        @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return('')
      end
      it 'will not trigger change' do
        expect(@provider.value).to eq 6
      end
    end
    context 'when value change is forced' do
      before(:each) do
        @resource = Puppet::Type.type(:lxd_config).new(
          # rubocop:disable HashSyntax
          {
            :ensure      => 'present',
            :config_name => 'global_images.auto_update_interval',
            :config      => ['images.auto_update_interval'],
            :force       => true,
            :value       => 6,
          },
          # rubocop:enable HashSyntax
        )
        @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
        expect(described_class).to receive(:lxc).with(['config', 'get', 'images.auto_update_interval']).and_return('')
      end
      it 'will trigger change' do
        expect(@provider.value).to eq ''
      end
    end
    context 'when core.trust_password is set, but should not change' do
      before(:each) do
        @resource = Puppet::Type.type(:lxd_config).new(
          # rubocop:disable HashSyntax
          {
            :ensure      => 'present',
            :config_name => 'global_core.trust_password',
            :config      => ['core.trust_password'],
            :force       => false,
            :value       => 'sekret',
          },
          # rubocop:enable HashSyntax
        )
        @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
        expect(described_class).to receive(:lxc).with(['config', 'get', 'core.trust_password']).and_return('true')
      end
      it 'will not trigger change' do
        expect(@provider.value).to eq 'sekret'
      end
    end
  end
end
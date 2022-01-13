# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_profile).provider(:profile) do
  before(:each) do
    @resource = Puppet::Type.type(:lxd_profile).new(
      {
        # rubocop:disable HashSyntax
        :ensure      => 'present',
        :name        => 'someprofile',
        :description => 'Some description',
        :config      => {},
        :devices     => {},
      },
      # rubocop:enable HashSyntax
    )
    @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
  end

  context 'without profiles' do
    before :each do
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/profiles']).returns('{}')
    end
    it 'will check if profile exists' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
    end
  end
  context 'with profiles' do
    before :each do
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/profiles']).returns(
        '[ "/1.0/profiles/someprofile" ]',
      )
    end
    it 'will check for appropriate output' do
      expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
    end
  end
  context 'with creating profile' do
    before :each do
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/profiles']).returns('{}')
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'POST', '-d', '{"name":"someprofile","description":"Some description","config":{},"devices":{}}', '/1.0/profiles']).returns('{}')
    end
    it 'will create appropriate config' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
      expect(@provider.create).to eq({}) # rubocop:todo InstanceVariable
    end
  end
end

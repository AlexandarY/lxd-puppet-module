# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_container).provider(:container) do
  before(:each) do
    @resource = Puppet::Type.type(:lxd_container).new(
      {
        # rubocop:disable HashSyntax
        :ensure   => 'present',
        :name     => 'container01',
        :config   => {},
        :devices  => {},
        :profiles => ['default'],
        :state    => 'started',
        :image    => 'bionic',
        # rubocop:enable HashSyntax
      },
    )
    @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
  end

  context 'without containers' do
    before :each do
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).returns('{}')
    end
    it 'will check if container exists' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
    end
  end
  context 'with lxc config' do
    before :each do
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).returns('[ "/1.0/containers/container01" ]')
    end
    it 'will check for appropriate config' do
      expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
    end
  end
  context 'with setting lxc config' do
    before :each do
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).returns('{}')
      described_class.expects(:lxc).with(
          [
            'query', '--wait', '-X', 'POST', '-d',
            '{"name":"container01","architecture":"x86_64","profiles":["default"],"config":{},"devices":{},"source":{"type":"image","alias":"bionic"}}',
            '/1.0/containers'
          ],
        ).returns('{}')
      described_class.expects(:lxc).with(['query', '--wait', '-X', 'PUT', '-d', '{"action":"start","timeout":30}', '/1.0/containers/container01/state']).returns('{}')
    end
    it 'will create appropriate config' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
      expect(@provider.create).to eq 'started' # rubocop:todo InstanceVariable
    end
  end
end

# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_storage).provider(:storage) do
  let(:resource) do
    Puppet::Type.type(:lxd_storage).new(
      name: 'default',
      driver: 'dir',
      source: '/opt/data',
      description: 'default storage',
      config: { 'volume.size' => '5GB' },
      provider: described_class.new,
    )
  end
  let(:provider) do
    resource.provider
  end

  describe 'self.instances' do
    context 'when generating list of instances on single node' do
      it 'will return an instance for each storage found' do
        expect(provider.class).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
        ).and_return('["/1.0/storage-pools/default"]')
        expect(provider.class).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default'],
        ).and_return(
          {
            'config' => { 'volume.size' => '5GB' },
            'description' => 'default storage',
            'driver' => 'dir',
            'locations' => ['none'],
            'name' => 'default',
            'status' => 'Created',
            'used_by' => []
          }.to_json,
        )

        # Run method to get instances
        instances = provider.class.instances

        expect(instances[0].name).to eql('default')
        expect(instances[0].config).to eql({ 'volume.size' => '5GB' })
        expect(instances[0].driver).to eql('dir')
        expect(instances[0].description).to eql('default storage')
      end
    end
    context 'when generating list of instances on cluster member' do
      context 'when not created on any member' do
        it 'will return an empty list' do
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
          ).and_return('[]')

          instances = provider.class.instances
          expect(instances).to eql([])
        end
      end
      context 'when created on a member, but not on all' do
        it 'will return a list with one object and :absent' do
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
          ).and_return('["/1.0/storage-pools/default"]')
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default'],
          ).and_return(
            {
              'config' => '{}',
              'description' => '',
              'driver' => 'dir',
              'locations' => [ 'node01' ],
              'name' => 'default',
              'status' => 'Pending',
              'used_by' => [],
            }.to_json,
          )

          instances = provider.class.instances
          expect(instances[0].name).to eql('default')
          expect(instances[0].exists?).to be(false)
        end
      end
    end
  end

  describe 'self.prefetch' do
    context 'when quering storage-pools' do
      it 'will return a list with existing storage-pools' do
        tmp_resource = Puppet::Type.type(:lxd_storage).new(
          name: 'default',
          driver: 'dir',
          description: 'temp',
          config: {},
        )

        expect(tmp_resource.provider.class).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
        ).and_return('["/1.0/storage-pools/default"]')
        expect(tmp_resource.provider.class).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default'],
        ).and_return(
          {
            'config' => { 'volume.size' => '5GB' },
            'description' => 'default storage',
            'driver' => 'dir',
            'locations' => ['none'],
            'name' => 'default',
            'status' => 'Created',
            'used_by' => []
          }.to_json,
        )

        tmp_resource.provider.class.prefetch('default' => tmp_resource)
        expect(tmp_resource.provider.config).to eq({ 'volume.size' => '5GB' })
        expect(tmp_resource.provider.description).to eq('default storage')
      end
    end
  end

  describe 'create' do
    context 'when creating on a single node LXD' do
      it 'will create successfully' do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/cluster'],
        ).and_return(
          {
            'enabled' => false,
            'member_config' => [],
            'server_name' => ''
          }.to_json,
        )
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'POST', '-d',
            {
              'name' => 'default',
              'driver' => 'dir',
              'description' => 'default storage',
              'config' => { 'volume.size' => '5GB', 'source' => '/opt/data' },
            }.to_json,
            '/1.0/storage-pools'
          ],
        ).and_return('')

        expect { provider.create }.not_to raise_error
      end
    end
    context 'when creating on a cluster member' do
      context 'when storage does not exist on all members' do
        it 'will create as Pending on local node' do
          expect(provider).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/cluster'],
          ).and_return(
            {
              'enabled' => true,
              'member_config' => [],
              'server_name' => 'node01'
            }.to_json,
          )
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
          ).and_return('[]')
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              {
                'name' => 'default',
                'driver' => 'dir',
                'description' => 'default storage',
                'config' => { 'source' => '/opt/data' }
              }.to_json,
              '/1.0/storage-pools?target=node01'
            ],
          ).and_return('')

          provider.create
        end
      end
      context 'when storage does exist on a member, but not current one' do
        it 'will create as Pending on local node' do
          expect(provider).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/cluster'],
          ).and_return(
            {
              'enabled' => true,
              'member_config' => [],
              'server_name' => 'node01'
            }.to_json,
          )
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
          ).and_return('[ "/1.0/storage-pools/default" ]')
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default'],
          ).and_return(
            {
              'config' => {},
              'description' => 'default storage',
              'driver' => 'dir',
              'locations' => [ 'node02', 'node03' ],
              'name' => 'default',
              'status' => 'Pending',
              'used_by' => [],
            }.to_json,
          )
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              {
                'name' => 'default',
                'driver' => 'dir',
                'description' => 'default storage',
                'config' => { 'source' => '/opt/data' }
              }.to_json,
              '/1.0/storage-pools?target=node01'
            ],
          ).and_return('')

          provider.create
        end
      end
      context 'when storage is Pending on all and needs global create' do
        it 'will do a global create to set storage in Created state' do
          expect(provider).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/cluster'],
          ).and_return(
            {
              'enabled' => true,
              'member_config' => [],
              'server_name' => 'node01'
            }.to_json,
          )
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
          ).and_return('[ "/1.0/storage-pools/default" ]')
          expect(provider.class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default'],
          ).and_return(
            {
              'config' => { 'volume.size' => '5GB' },
              'description' => 'default storage',
              'driver' => 'dir',
              'locations' => [ 'node01', 'node02', 'node03' ],
              'name' => 'default',
              'status' => 'Pending',
              'used_by' => [],
            }.to_json,
          )
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              {
                'name' => 'default',
                'driver' => 'dir',
                'description' => 'default storage',
                'config' => { 'volume.size' => '5GB' }
              }.to_json,
              '/1.0/storage-pools'
            ],
          ).and_return('')

          provider.create
        end
      end
    end
  end

  describe 'destroy' do
    context 'when deleting an existing storage-pool' do
      it 'will complete successfully' do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'DELETE', '/1.0/storage-pools/default'],
        ).and_return('\n')

        expect { provider.destroy }.not_to raise_error
      end
    end
  end

  describe 'config' do
    let(:resource) do
      Puppet::Type.type(:lxd_storage).new(
        name: 'default',
        driver: 'lvm',
        source: '/dev/sdb',
        description: 'default storage',
        config: {
          'lvm.thinpool_name' => 'default-lvm',
          'volume.size' => '5GB'
        },
        provider: described_class.new,
      )
    end
    let(:provider) do
      resource.provider
    end

    context 'when changing storage-pool config on a single node LXD' do
      it 'will complete successfully' do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/cluster'],
        ).and_return(
          {
            'enabled' => false,
            'member_config' => [],
            'server_name' => ''
          }.to_json,
        )
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PATCH', '-d',
            { 'config' => { 'lvm.thinpool_name' => 'new-default-lvm', 'volume.size' => '10GB' } }.to_json,
            '/1.0/storage-pools/default'
          ],
        ).and_return('\n')

        provider.config = { 'lvm.thinpool_name' => 'new-default-lvm', 'volume.size' => '10GB' }
      end
    end
    context 'when changing storage-pool config on a LXD cluster member' do
      it 'will complete successfully' do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/cluster'],
        ).and_return(
          {
            'enabled' => true,
            'member_config' => [],
            'server_name' => 'node01'
          }.to_json,
        )
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PATCH', '-d',
            { 'config' => { 'lvm.thinpool_name' => 'new-default-lvm' } }.to_json,
            '/1.0/storage-pools/default?target=node01'
          ],
        ).and_return('\n')
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PATCH', '-d',
            { 'config' => { 'volume.size' => '10GB' } }.to_json,
            '/1.0/storage-pools/default'
          ],
        ).and_return('\n')

        provider.config = { 'lvm.thinpool_name' => 'new-default-lvm', 'volume.size' => '10GB' }
      end
    end
  end

  describe 'description' do
    context 'when changing storage-pool description' do
      it 'will complete successfully' do
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PATCH', '-d',
            { 'description' => 'new description' }.to_json,
            '/1.0/storage-pools/default'
          ],
        ).and_return('\n')

        expect { provider.description = 'new description' }.not_to raise_error
      end
    end
  end

  describe 'driver' do
    context 'when changing driver of existing storage' do
      it 'will raise an exception' do
        expect { provider.driver = 'lvm' }.to raise_error(NotImplementedError)
      end
    end
  end
end

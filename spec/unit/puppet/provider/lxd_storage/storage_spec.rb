# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_storage).provider(:storage) do
  let(:params) do
    {
      title: 'default-storage',
      name: 'default-storage',
      driver: 'dir',
      description: 'default storage driver',
      config: { 'volume.size' => '1GiB' },
      provider: described_class.name,
    }
  end
  let(:resource) do
    Puppet::Type.type(:lxd_storage).new(params)
  end
  let(:provider) do
    resource.provider
  end

  describe '.exists?' do
    context 'when not existing' do
      before(:each) do
        expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/storage-pools']).and_return('[]')
      end
      it 'will return false' do
        expect(provider.exists?).to be false
      end
    end
    context 'when existing' do
      before(:each) do
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'GET', '/1.0/storage-pools'
          ],
        ).and_return('["/1.0/storage-pools/default-storage"]')
      end
      it 'will return true' do
        expect(provider.exists?).to be true
      end
    end
  end

  describe '.create' do
    context 'when not existing' do
      before(:each) do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
        ).and_return('[]')
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'POST', '-d',
            '{"name":"default-storage","driver":"dir","description":"default storage driver","config":{"volume.size":"1GiB"}}',
            '/1.0/storage-pools'
          ],
        ).and_return('')
      end
      it 'will create without error' do
        expect(provider.exists?).to be false
        expect { provider.create }.not_to raise_error
      end
    end
  end

  describe '.destroy' do
    context 'when not existing' do
      before(:each) do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools'],
        ).and_return('["/1.0/storage-pools/default-storage"]')
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'DELETE', '/1.0/storage-pools/default-storage'],
        ).and_return('\n')
      end
      it 'will completed without error' do
        expect(provider.exists?).to be true
        expect { provider.destroy }.not_to raise_error
      end
    end
  end

  describe '.config' do
    context 'change existing config' do
      before(:each) do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default-storage'],
        ).and_return(
          {
            'config' => {},
            'description' => 'default storage pool',
            'driver' => 'dir',
            'locations' => ['none'],
            'name' => 'default-storage',
            'status' => 'Created',
            'used-by' => []
          }.to_json,
        )
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PATCH', '-d',
            '{"config":{"volume.size":"1GiB"}}', '/1.0/storage-pools/default-storage'
          ],
        ).and_return('\n')
      end
      it 'will not raise error' do
        provider
        expect(provider.config).to eql({})
        expect { provider.config = { 'volume.size' => '1GiB' } }.not_to raise_error
      end
    end
    context 'when source and volatile are set' do
      before(:each) do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default-storage'],
        ).and_return(
          {
            'config' => {
              'source' => '/path/to/somewhere',
              'volatile.initial_source' => true
            },
            'description' => 'default storage pool',
            'driver' => 'dir',
            'locations' => ['none'],
            'name' => 'default-storage',
            'status' => 'Created',
            'used-by' => []
          }.to_json,
        )
      end
      it 'will not return them' do
        provider
        expect(provider.config).to eql({})
      end
    end
  end

  describe '.description' do
    context 'change existing description' do
      before(:each) do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default-storage'],
        ).and_return(
          '{"config":{},"description":"default storage pool","driver":"dir","locations":["none"],"name":"default-storage","status":"Created","used-by":[]}',
        )
        expect(provider).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PATCH', '-d',
            '{"description":"new description"}', '/1.0/storage-pools/default-storage'
          ],
        ).and_return('\n')
      end
      it 'will not raise error' do
        provider
        expect(provider.description).to eq('default storage pool')
        expect { provider.description = 'new description' }.not_to raise_error
      end
    end
  end

  describe '.driver' do
    context 'change of driver' do
      before(:each) do
        expect(provider).to receive(:lxc).with(
          ['query', '--wait', '-X', 'GET', '/1.0/storage-pools/default-storage'],
        ).and_return(
          {
            'config' => {},
            'description' => 'default storage pool',
            'driver' => 'dir',
            'locations' => ['none'],
            'name' => 'default-storage',
            'status' => 'Created',
            'used-by' => [],
          }.to_json,
        )
      end
      it 'will result in error' do
        provider
        expect(provider.driver).to eq('dir')
        expect { provider.driver = 'lvm' }.to raise_error %r{You cannot modify driver of already created storage!}
      end
    end
  end
end

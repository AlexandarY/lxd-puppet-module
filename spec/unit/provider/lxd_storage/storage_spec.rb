# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_storage).provider(:storage) do
  context 'with ensure present' do
    before(:each) do
      @resource = Puppet::Type.type(:lxd_storage).new(
        {
          # rubocop:disable HashSyntax
          :ensure      => 'present',
          :name        => 'somestorage',
          :driver      => 'dir',
          :description => 'desc',
          :config      => { 'source' => '/tmp/somestoragepool' },
          # rubocop:enable HashSyntax
        },
      )
      @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
    end

    context 'without storage-pools' do
      before :each do
        expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/storage-pools']).and_return('{}')
      end
      it 'will check if storage exists' do
        expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
      end
    end
    context 'with storage-pools' do
      before :each do
        expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/storage-pools']).and_return('["/1.0/storage-pools/somestorage"]')
      end
      it 'will check for appropriate output' do
        expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
      end
    end
    context 'with creating storage' do
      before :each do
        expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/storage-pools']).and_return('{}')
        expect(described_class).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'POST', '-d',
            '{"name":"somestorage","driver":"dir","description":"desc","config":{"source":"/tmp/somestoragepool"}}',
            '/1.0/storage-pools'
          ],
        ).and_return('{}')
      end
      it 'will create appropriate config' do
        expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
        expect(@provider.create).to eq({}) # rubocop:todo InstanceVariable
      end
    end
  end

  context 'with ensure absent' do
    before(:each) do
      @resource = Puppet::Type.type(:lxd_storage).new(
        {
          # rubocop:disable HashSyntax
          :ensure      => 'absent',
          :name        => 'somestorage',
          :driver      => 'dir',
          :description => 'desc',
          :config      => { 'source' => '/tmp/somestoragepool' },
          # rubocop:enable HashSyntax
        },
      )
      @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
    end

    context 'with creating storage' do
      before :each do
        expect(described_class).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'GET', '/1.0/storage-pools'
          ],
        ).and_return('["/1.0/storage-pools/somestorage"]')
        expect(described_class).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'DELETE', '/1.0/storage-pools/somestorage'
          ],
        ).and_return('{}')
      end
      it 'will create appropriate config' do
        expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
        expect(@provider.destroy).to eq({}) # rubocop:todo InstanceVariable
      end
    end
  end
end

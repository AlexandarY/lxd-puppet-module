# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_container).provider(:container) do
  describe 'with container' do
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
          :instance_type => 'container'
          # rubocop:enable HashSyntax
        },
      )
      @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
    end

    describe '.exists?' do
      context 'when not existing' do
        before(:each) do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).and_return('{}')
        end
        it 'does not exist' do
          expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
        end
      end
      context 'when existing' do
        before(:each) do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).and_return(
            '[ "/1.0/containers/container01" ]',
          )
        end
        it 'exists' do
          expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
        end
      end
    end

    describe '.create' do
      context 'when not existing' do
        before(:each) do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).and_return('{}')
          expect(described_class).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              '{"name":"container01","architecture":"x86_64","profiles":["default"],"config":{},"devices":{},"source":{"type":"image","alias":"bionic"},"type":"container"}',
              '/1.0/containers'
            ],
          ).and_return('{}')
          expect(described_class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'PUT', '-d', '{"action":"start","timeout":30}', '/1.0/containers/container01/state'],
          ).and_return(
            '{
              "class": "task",
              "created_at": "2022-01-25T01:17:42.932601606+02:00",
              "description": "Starting instance",
              "err": "",
              "id": "f179ea5b-6fd7-48c9-b0b7-6f4f616b1bca",
              "location": "none",
              "may_cancel": false,
              "metadata": null,
              "resources": {
                  "instances": [
                      "/1.0/instances/container01"
                  ]
              },
              "status": "Success",
              "status_code": 200,
              "updated_at": "2022-01-25T01:17:42.932601606+02:00"
            }',
          )
        end
        it 'create successfully' do
          expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
          expect { @provider.create }.not_to raise_error # rubocop:todo InstanceVariable
        end
      end
    end

    describe '.destroy' do
      context 'when existing' do
        before(:each) do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).and_return(
            '[ "/1.0/containers/container01" ]',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'DELETE', '/1.0/containers/container01']).and_return(
            '{
              "class": "task",
              "created_at": "2022-01-25T01:10:01.94983761+02:00",
              "description": "Deleting instance",
              "err": "",
              "id": "7ee89667-9895-4ffb-b2d6-d42789d60616",
              "location": "none",
              "may_cancel": false,
              "metadata": null,
              "resources": {
                  "containers": [
                      "/1.0/containers/container01"
                  ],
                  "instances": [
                      "/1.0/instances/container01"
                  ]
              },
              "status": "Success",
              "status_code": 200,
              "updated_at": "2022-01-25T01:10:01.94983761+02:00"
            }',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers/container01/state']).and_return(
            '{
              "cpu": {
                      "usage": 0
              },
              "disk": {},
              "memory": {
                      "swap_usage": 0,
                      "swap_usage_peak": 0,
                      "usage": 0,
                      "usage_peak": 0
              },
              "network": null,
              "pid": 0,
              "processes": 0,
              "status": "Stopped",
              "status_code": 102
            }',
          )
        end
        it 'delete successfully' do
          expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
          expect { @provider.destroy }.not_to raise_error # rubocop:todo InstanceVariable
        end
      end
    end
  end

  describe 'with virtual-machine' do
    before(:each) do
      @resource = Puppet::Type.type(:lxd_container).new(
        {
          # rubocop:disable HashSyntax
          :ensure   => 'present',
          :name     => 'vm01',
          :config   => {},
          :devices  => {},
          :profiles => ['default'],
          :state    => 'started',
          :image    => 'bionic',
          :instance_type => 'virtual-machine'
          # rubocop:enable HashSyntax
        },
      )
      @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
    end

    describe '.create' do
      context 'when not existing' do
        before(:each) do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/containers']).and_return('{}')
          expect(described_class).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              '{"name":"vm01","architecture":"x86_64","profiles":["default"],"config":{},"devices":{},"source":{"type":"image","alias":"bionic"},"type":"virtual-machine"}',
              '/1.0/containers'
            ],
          ).and_return('{}')
          expect(described_class).to receive(:lxc).with(
            ['query', '--wait', '-X', 'PUT', '-d', '{"action":"start","timeout":30}', '/1.0/containers/vm01/state'],
          ).and_return(
            '{
              "class": "task",
              "created_at": "2022-01-25T01:17:42.932601606+02:00",
              "description": "Starting instance",
              "err": "",
              "id": "f179ea5b-6fd7-48c9-b0b7-6f4f616b1bca",
              "location": "none",
              "may_cancel": false,
              "metadata": null,
              "resources": {
                  "instances": [
                      "/1.0/instances/vm01"
                  ]
              },
              "status": "Success",
              "status_code": 200,
              "updated_at": "2022-01-25T01:17:42.932601606+02:00"
            }',
          )
        end
        it 'create successfully' do
          expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
          expect { @provider.create }.not_to raise_error # rubocop:todo InstanceVariable
        end
      end
    end
  end
end

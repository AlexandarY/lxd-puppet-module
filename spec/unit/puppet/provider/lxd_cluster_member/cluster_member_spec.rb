# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_cluster_member).provider(:cluster_member) do
  describe 'on initial node creation' do
    before(:each) do
      @resource = Puppet::Type.type(:lxd_cluster_member).new(
        # rubocop:disable HashSyntax
        {
          :name => 'member01',
          :ensure => 'present',
          :enabled => true,
          :cluster_password => 'sekret',
          :address => '192.168.0.10:8443',
          :join_member => '192.168.0.10:8443',
          :other_members => ['192.168.0.11:8443', '192.168.0.12:8443']
        },
        # rubocop:enable HashSyntax
      )
      @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
    end

    describe '.exists?' do
      context 'when clustering is not enabled' do
        before :each do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
            '{
                "enabled": false,
                "member_config": [],
                "server_name": ""
              }',
          )
        end
        it 'return false' do
          expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
        end
      end

      context 'when clustering is enabled' do
        before :each do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
            '{
                "enabled": true,
                "member_config": [
                    {
                        "description": "\"source\" property for storage pool \"test\"",
                        "entity": "storage-pool",
                        "key": "source",
                        "name": "test",
                        "value": ""
                    }
                ],
                "server_name": "clustertest3"
              }',
          )
        end
        it 'return true' do
          expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
        end
      end
    end

    describe '.create' do
      context 'when successful' do
        before :each do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
            '{
                "enabled": false,
                "member_config": [],
                "server_name": ""
            }',
          )
          expect(described_class).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'PUT', '--data',
              '{"enabled":true,"server_address":"192.168.0.10:8443","server_name":"member01"}',
              '/1.0/cluster'
            ],
          ).and_return(
            '{
              "class": "task",
              "created_at": "2022-01-21T16:24:04.445412856Z",
              "description": "Creating bootstrap node",
              "err": "",
              "id": "1e11e241-3ff9-4db0-8f64-196248f5866a",
              "location": "member01",
              "may_cancel": false,
              "metadata": null,
              "resources": {
                  "cluster": null
              },
              "status": "Success",
              "status_code": 200,
              "updated_at": "2022-01-21T16:24:04.445412856Z"
            }',
          )
        end
        it 'raise no errors' do
          expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
          expect { @provider.create }.not_to raise_error # rubocop:todo InstanceVariable
        end
      end
      context 'when it fails' do
        before :each do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
            '{
                "enabled": false,
                "member_config": [],
                "server_name": ""
            }',
          )
          expect(described_class).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'PUT', '--data',
              '{"enabled":true,"server_address":"192.168.0.10:8443","server_name":"member01"}',
              '/1.0/cluster'
            ],
          ).and_return('Error: Unexpected error')
        end
        it 'raises error' do
          expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
          expect { @provider.create }.to raise_error %r{Error during cluster init} # rubocop:todo InstanceVariable
        end
      end
    end
  end

  describe 'on new member joining cluster' do
    before(:each) do
      @resource = Puppet::Type.type(:lxd_cluster_member).new(
        # rubocop:disable HashSyntax
        {
          :name => 'member02',
          :ensure => 'present',
          :enabled => true,
          :cluster_password => 'sekret',
          :address => '192.168.0.11:8443',
          :join_member => '192.168.0.10:8443',
          :other_members => ['192.168.0.10:8443', '192.168.0.12:8443']
        },
        # rubocop:enable HashSyntax
      )
      @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
    end

    context 'when successful' do
      before(:each) do
        expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
          '{
              "enabled": false,
              "member_config": [],
              "server_name": ""
          }',
        )
        allow(@provider).to receive(:get_cluster_cert_from_member).with('192.168.0.10:8443').and_return( # rubocop:todo InstanceVariable
          '-----BEGIN CERTIFICATE-----...rest of cert here ...-----END CERTIFICATE-----',
        )
        expect(described_class).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PUT', '--data',
            '{"cluster_address":"192.168.0.10:8443","cluster_certificate":"-----BEGIN CERTIFICATE-----...rest of cert here ...-----END CERTIFICATE-----","cluster_password":"sekret","enabled":true,"server_address":"192.168.0.11:8443","server_name":"member02"}', # rubocop:todo LineLength
            '/1.0/cluster'
          ],
        ).and_return(
          '{
            "class": "task",
            "created_at": "2022-01-21T16:42:09.622389219Z",
            "description": "Joining cluster",
            "err": "",
            "id": "09c8241a-b59a-43f2-a89d-86e0a6e66f78",
            "location": "member02",
            "may_cancel": false,
            "metadata": null,
            "resources": {
                "cluster": null
            },
            "status": "Success",
            "status_code": 200,
            "updated_at": "2022-01-21T16:42:09.622389219Z"
          }',
        )
      end
      it 'raises no error' do
        expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
        expect { @provider.create }.not_to raise_error # rubocop:todo InstanceVariable
      end
    end

    context 'on error joining' do
      before(:each) do
        expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
          '{
              "enabled": false,
              "member_config": [],
              "server_name": ""
          }',
        )
        allow(@provider).to receive(:get_cluster_cert_from_member).with('192.168.0.10:8443').and_return( # rubocop:todo InstanceVariable
          '-----BEGIN CERTIFICATE-----...rest of cert here ...-----END CERTIFICATE-----',
        )
        expect(described_class).to receive(:lxc).with(
          [
            'query', '--wait', '-X', 'PUT', '--data',
            '{"cluster_address":"192.168.0.10:8443","cluster_certificate":"-----BEGIN CERTIFICATE-----...rest of cert here ...-----END CERTIFICATE-----","cluster_password":"sekret","enabled":true,"server_address":"192.168.0.11:8443","server_name":"member02"}', # rubocop:todo LineLength
            '/1.0/cluster'
          ],
        ).and_return(
          'Error: unable to join cluster example error',
        )
      end
      it 'raises an error' do
        expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
        expect { @provider.create }.to raise_error %r{Error while attempting to join cluster} # rubocop:todo InstanceVariable
      end
    end

    context 'on error connecting to member' do
      before(:each) do
        expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
          '{
            "enabled": false,
            "member_config": [],
            "server_name": ""
          }',
        )
      end
      it 'raises an error' do
        expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
        expect { @provider.create }.to raise_error %r{Failed to open TCP connection to} # rubocop:todo InstanceVariable
      end
    end
  end
end

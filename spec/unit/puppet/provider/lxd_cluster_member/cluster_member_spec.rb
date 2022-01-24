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

    describe '.destroy' do
      context 'when successful' do
        before(:each) do
          expect(described_class).to receive(:lxc).twice.with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
            '{
              "enabled": true,
              "member_config": [],
              "server_name": "member01"
            }',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster/members']).and_return(
            '[ "/1.0/cluster/members/member01", "/1.0/cluster/members/member02", "/1.0/cluster/members/member03" ]',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'DELETE', '/1.0/cluster/members/member01']).and_return('\n')
        end
        it 'raises no errors' do
          expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
          expect { @provider.destroy }.not_to raise_error # rubocop:todo InstanceVariable
        end
      end
      context 'when it fails' do
        before(:each) do
          expect(described_class).to receive(:lxc).twice.with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
            '{
              "enabled": true,
              "member_config": [],
              "server_name": "member01"
            }',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster/members']).and_return(
            '[ "/1.0/cluster/members/member01", "/1.0/cluster/members/member02", "/1.0/cluster/members/member03" ]',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'DELETE', '/1.0/cluster/members/member01']).and_return(
            'Error: Some unknown error occurred example',
          )
        end
        it 'raises puppet::error' do
          expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
          expect { @provider.destroy }.to raise_error %r{Error encountered while leaving cluster} # rubocop:todo InstanceVariable
        end
      end
      context 'when last member' do
        before(:each) do
          expect(described_class).to receive(:lxc).twice.with(['query', '--wait', '-X', 'GET', '/1.0/cluster']).and_return(
            '{
              "enabled": true,
              "member_config": [],
              "server_name": "member01"
            }',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster/members']).and_return(
            '[ "/1.0/cluster/members/member01" ]',
          )
        end
        it 'will not run `leave_cluster` and not raise error' do
          expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
          expect { @provider.destroy }.not_to raise_error # rubocop:todo InstanceVariable
        end
      end
    end

    describe '.enabled' do
      context 'when disabled and want enable' do
        before(:each) do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster/members/member01']).and_return(
            '{
              "architecture": "x86_64",
              "config": {},
              "database": true,
              "description": "",
              "failure_domain": "default",
              "groups": [
                  "default"
              ],
              "message": "Unavailable due to maintenance",
              "roles": [
                  "database-leader",
                  "database"
              ],
              "server_name": "member01",
              "status": "Evacuated",
              "url": "https://192.168.0.10:8443"
            }',
          )
          expect(described_class).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '--data',
              '{"action":"restore"}', '/1.0/cluster/members/member01/state'
            ],
          ).and_return(
            '{
              "class": "task",
              "created_at": "2022-01-24T14:20:15.333422606Z",
              "description": "Restoring cluster member",
              "err": "",
              "id": "59d26d8b-168f-49a9-b1f8-463dae44f2bd",
              "location": "member01",
              "may_cancel": false,
              "metadata": null,
              "resources": null,
              "status": "Success",
              "status_code": 200,
              "updated_at": "2022-01-24T14:20:15.333422606Z"
            }',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster/members/member01']).and_return(
            '{
             "architecture": "x86_64",
              "config": {},
              "database": true,
              "description": "",
              "failure_domain": "default",
              "groups": [
                      "default"
              ],
              "message": "Fully operational",
              "roles": [
                      "database-leader",
                      "database"
              ],
              "server_name": "clbt04",
              "status": "Online",
              "url": "https://192.168.0.10:8443"
            }',
          )
        end
        it 'without errors' do
          expect(@provider.enabled).to be false # rubocop:todo InstanceVariable
          expect { @provider.enabled = true }.not_to raise_error # rubocop:todo InstanceVariable
          expect(@provider.enabled).to be true # rubocop:todo InstanceVariable
        end
      end

      context 'when enabled and want disable' do
        before(:each) do
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster/members/member01']).and_return(
            '{
              "architecture": "x86_64",
              "config": {},
              "database": true,
              "description": "",
              "failure_domain": "default",
              "groups": [
                      "default"
              ],
              "message": "Fully operational",
              "roles": [
                      "database-leader",
                      "database"
              ],
              "server_name": "member01",
              "status": "Online",
              "url": "https://192.168.0.10:8443"
            }',
          )
          expect(described_class).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '--data',
              '{"action":"evacuate"}', '/1.0/cluster/members/member01/state'
            ],
          ).and_return(
            '{
              "class": "task",
              "created_at": "2022-01-24T14:16:22.421543415Z",
              "description": "Evacuating cluster member",
              "err": "",
              "id": "691c1e47-7fc4-47c6-9d6c-50c6acf9777e",
              "location": "member01",
              "may_cancel": false,
              "metadata": null,
              "resources": null,
              "status": "Success",
              "status_code": 200,
              "updated_at": "2022-01-24T14:16:22.421543415Z"
            }',
          )
          expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/cluster/members/member01']).and_return(
            '{
              "architecture": "x86_64",
              "config": {},
              "database": true,
              "description": "",
              "failure_domain": "default",
              "groups": [
                      "default"
              ],
              "message": "Unavailable due to maintenance",
              "roles": [
                      "database-leader",
                      "database"
              ],
              "server_name": "member01",
              "status": "Evacuated",
              "url": "https://192.168.0.10:8443"
            }',
          )
        end

        it 'without errors' do
          expect(@provider.enabled).to be true # rubocop:todo InstanceVariable
          expect { @provider.enabled = false }.not_to raise_error # rubocop:todo InstanceVariable
          expect(@provider.enabled).to be false # rubocop:todo InstanceVariable
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

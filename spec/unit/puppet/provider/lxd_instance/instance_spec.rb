require 'spec_helper'

describe Puppet::Type.type(:lxd_instance).provider(:instance) do
  describe 'with container' do
    let(:params) do
      {
        title: 'ct01',
        name: 'ct01',
        type: 'container',
        image: 'ubuntu:focal:amd64:default:container',
        config: { 'limits.memory' => '2GB' },
        devices: {},
        state: 'started',
        profiles: ['default']
      }
    end
    let(:resource) do
      Puppet::Type.type(:lxd_instance).new(params)
    end
    let(:provider) do
      resource.provider
    end
    let(:ct_info) do
      {
        'architecture': 'x86_64',
        'config': {
          'image.architecture': 'amd64',
          'image.description': 'Ubuntu focal amd64 (20220209_07:42)',
          'image.os': 'Ubuntu',
          'image.release': 'focal',
          'image.serial': '20220209_07:42',
          'image.type': 'squashfs',
          'image.variant': 'default',
          'volatile.base_image': '0a6a3c3a97bf8f0c17e6dd60b9da7e0a634f2996a85e49d3d0bb76ffd1c19495',
          'volatile.eth0.host_name': 'veth3736d4cb',
          'volatile.eth0.hwaddr': '00:16:3e:6a:54:d7',
          'volatile.idmap.base': '0',
          'volatile.idmap.current': '... data ...',
          'volatile.idmap.next': '... data ...',
          'volatile.last_state.idmap': '... data ...',
          'volatile.last_state.power': 'RUNNING',
          'volatile.uuid': '00bcaaf0-2ea1-4be4-b781-8f5923b1dc7a'
        },
        'created_at': '2022-02-09T14:48:58.974265001Z',
        'description': '',
        'devices': {},
        'ephemeral': false,
        'expanded_config': {
          'image.architecture': 'amd64',
          'image.description': 'Ubuntu focal amd64 (20220209_07:42)',
          'image.os': 'Ubuntu',
          'image.release': 'focal',
          'image.serial': '20220209_07:42',
          'image.type': 'squashfs',
          'image.variant': 'default',
          'limits.cpu.allowance': '200%',
          'volatile.base_image': '0a6a3c3a97bf8f0c17e6dd60b9da7e0a634f2996a85e49d3d0bb76ffd1c19495',
          'volatile.eth0.host_name': 'veth3736d4cb',
          'volatile.eth0.hwaddr': '00:16:3e:6a:54:d7',
          'volatile.idmap.base': '0',
          'volatile.idmap.current': '... data ...',
          'volatile.idmap.next': '... data ...',
          'volatile.last_state.idmap': '... data ...',
          'volatile.last_state.power': 'RUNNING',
          'volatile.uuid': '00bcaaf0-2ea1-4be4-b781-8f5923b1dc7a'
        },
        'expanded_devices': {
          'eth0': {
            'name': 'eth0',
            'nictype': 'bridged',
            'parent': 'br0',
            'type': 'nic'
          },
          'root': {
            'path': '/',
            'pool': 'default',
            'type': 'disk'
          }
        },
        'last_used_at': '2022-02-09T14:49:02.516413166Z',
        'location': 'none',
        'name': 'ct01',
        'profiles': [
          'default',
        ],
        'project': 'default',
        'stateful': false,
        'status': 'Running',
        'status_code': 103,
        'type': 'container'
      }
    end

    describe '.exists?' do
      context 'when not existing' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances']).and_return('[]')
        end
        it 'returns false' do
          expect(provider.exists?).to be false
        end
      end
      context 'when existing' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances']).and_return(
            '[ "/1.0/instances/ct01" ]',
          )
        end
        it 'returns true' do
          expect(provider.exists?).to be true
        end
      end
    end
    describe '.create' do
      context 'when create runs without errors raised' do
        before(:each) do
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              {
                'name' => 'ct01',
                'architecture' => 'x86_64',
                'profiles' => ['default'],
                'config' => {
                  'limits.memory' => '2GB',
                },
                'devices' => {},
                'source' => {
                  'type' => 'image',
                  'alias' => 'ubuntu:focal:amd64:default:container'
                },
                'type' => 'container'
              }.to_json,
              '/1.0/instances'
            ],
          ).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T16:16:08.431633713+02:00',
              'description': 'Creating instance',
              'err': '',
              'id': 'bc4dafb3-a9a0-49f2-a48c-9516aaa9714f',
              'location': 'none',
              'may_cancel': false,
              'metadata': {
                'create_instance_from_image_unpack_progress': 'Unpack: 100% (3.95GB/s)',
                'progress': {
                  'percent': '100',
                  'speed': '3953216374',
                  'stage': 'create_instance_from_image_unpack'
                }
              },
              'resources': {
                'containers': [
                  '/1.0/containers/ct01',
                ],
                'instances': [
                  '/1.0/instances/ct01',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T16:16:08.504765329+02:00'
            }.to_json,
          )
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'PUT', '-d', '{"action":"start"}', '/1.0/instances/ct01/state']).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T15:24:13.591094148+02:00',
              'description': 'Stopping instance',
              'err': '',
              'id': '715186e7-2a71-439e-a32b-f50c1a210bb7',
              'location': 'none',
              'may_cancel': false,
              'metadata': nil,
              'resources': {
                'instances': [
                  '/1.0/instances/ct01',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T15:24:13.591094148+02:00'
            }.to_json,
          )
        end
        it 'will not raise error' do
          expect { provider.create }.not_to raise_error
        end
      end
      context 'when create runs and error is raised' do
        before(:each) do
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              {
                'name' => 'ct01',
                'architecture' => 'x86_64',
                'profiles' => ['default'],
                'config' => {
                  'limits.memory' => '2GB',
                },
                'devices' => {},
                'source' => {
                  'type' => 'image',
                  'alias' => 'ubuntu:focal:amd64:default:container'
                },
                'type' => 'container'
              }.to_json,
              '/1.0/instances'
            ],
          ).and_return('Error: Unknown error!')
        end
        it 'will raise error' do
          expect { provider.create }.to raise_error(Puppet::Error)
        end
      end
    end
    describe '.destroy' do
      context 'when destroy runs without errors raised' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'PUT', '-d', '{"action":"stop"}', '/1.0/instances/ct01/state']).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T15:24:13.591094148+02:00',
              'description': 'Stopping instance',
              'err': '',
              'id': '715186e7-2a71-439e-a32b-f50c1a210bb7',
              'location': 'none',
              'may_cancel': false,
              'metadata': nil,
              'resources': {
                'instances': [
                  '/1.0/instances/ct01',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T15:24:13.591094148+02:00'
            }.to_json,
          )
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'DELETE', '/1.0/instances/ct01']).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T15:45:50.445070336+02:00',
              'description': 'Deleting instance',
              'err': '',
              'id': '10c18d8d-bd8e-41e3-a1e2-fa1fea4c3cbf',
              'location': 'none',
              'may_cancel': false,
              'metadata': nil,
              'resources': {
                'containers': [
                  '/1.0/containers/ptrm',
                ],
                'instances': [
                  '/1.0/instances/ptrm',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T15:45:50.445070336+02:00'
            }.to_json,
          )
        end
        it 'will not raise errors' do
          provider.destroy
        end
      end
      context 'when destroy runs and errors are raised' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'PUT', '-d', '{"action":"stop"}', '/1.0/instances/ct01/state']).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T15:24:13.591094148+02:00',
              'description': 'Stopping instance',
              'err': '',
              'id': '715186e7-2a71-439e-a32b-f50c1a210bb7',
              'location': 'none',
              'may_cancel': false,
              'metadata': nil,
              'resources': {
                'instances': [
                  '/1.0/instances/ct01',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T15:24:13.591094148+02:00'
            }.to_json,
          )
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'DELETE', '/1.0/instances/ct01']).and_return('Error: Not found')
        end
        it 'will raise error' do
          expect { provider.destroy }.to raise_error(Puppet::Error)
        end
      end
    end
    describe '.state' do
      context 'when retrieving state and no error occurs' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
        end
        it 'will not raise error' do
          provider
          expect(provider.state).to eql 'started'
        end
      end
      context 'when retrieving state and error occurs' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return('Error: Not found')
        end
        it 'will raise an error' do
          provider
          expect { provider.state }.to raise_error(Puppet::Error)
        end
      end
    end
    describe '.state=' do
      context 'when setting state and no errors are raised' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'PUT', '-d', '{"action":"stop"}', '/1.0/instances/ct01/state']).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T15:24:13.591094148+02:00',
              'description': 'Stopping instance',
              'err': '',
              'id': '715186e7-2a71-439e-a32b-f50c1a210bb7',
              'location': 'none',
              'may_cancel': false,
              'metadata': nil,
              'resources': {
                'instances': [
                  '/1.0/instances/ct01',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T15:24:13.591094148+02:00'
            }.to_json,
          )
        end
        it 'will not raise an error' do
          provider
          expect { provider.state }.not_to raise_error
          expect { provider.state = 'stopped' }.not_to raise_error
        end
      end
      context 'when setting state and error is raised' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'PUT', '-d', '{"action":"stop"}', '/1.0/instances/ct01/state']).and_return('Error: Not Found')
        end
        it 'will raise an error' do
          provider
          expect { provider.state }.not_to raise_error
          expect { provider.state = 'stopped' }.to raise_error(Puppet::Error)
        end
      end
    end
    describe '.config' do
      context 'when retrieving config' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
        end
        it 'no errors will be raised' do
          provider
          # should be empty, as current ct01 config doesn't include the values
          # and we also verify it excludes the ones we don't care about, as not explicitly managed
          expect(provider.config).to eql({})
        end
      end
    end
    describe '.config=' do
      context 'when setting config' do
        before(:each) do
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'PATCH', '-d',
              { 'config' => { 'limits.memory' => '2GB' } }.to_json,
              '/1.0/instances/ct01'
            ],
          ).and_return('')
        end
        it 'no erros will be raised' do
          expect { provider.config = { 'limits.memory' => '2GB' } }.not_to raise_error
        end
      end
    end
    describe '.devices' do
      context 'when retrieving device' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
        end
        it 'no errors will be raised' do
          provider
          expect(provider.devices).to eql({})
        end
      end
    end
    describe '.devices=' do
      context 'when setting devices' do
        before(:each) do
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'PATCH', '-d',
              { 'devices' => { 'mount-dir' => { 'path' => '/path/in/ct01', 'source' => '/path/on/host', 'type' => 'disk' } } }.to_json,
              '/1.0/instances/ct01'
            ],
          ).and_return('')
        end
        it 'no errors will be raised' do
          expect {
            provider.devices = { 'mount-dir' => { 'path' => '/path/in/ct01', 'source' => '/path/on/host', 'type' => 'disk' } }
          }.not_to raise_error
        end
      end
    end
    describe '.profiles' do
      context 'when retrieving profiles' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances/ct01']).and_return(ct_info.to_json)
        end
        it 'no errors will be raised' do
          provider
          expect(provider.profiles).to eql(['default'])
        end
      end
    end
    describe '.profiles=' do
      context 'when setting profiles' do
        before(:each) do
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'PATCH', '-d',
              { 'profiles' => ['default', 'network'] }.to_json,
              '/1.0/instances/ct01'
            ],
          ).and_return('')
        end
        it 'no errors will be raised' do
          expect { provider.profiles = ['default', 'network'] }.not_to raise_error
        end
      end
    end
  end

  describe 'with virtual-machine' do
    let(:params) do
      {
        title: 'vm01',
        name: 'vm01',
        type: 'virtual-machine',
        image: 'ubuntu:focal:amd64:default:virtual-machine',
        config: { 'limits.memory' => '2GB' },
        devices: {},
        state: 'started',
        profiles: ['default']
      }
    end
    let(:resource) do
      Puppet::Type.type(:lxd_instance).new(params)
    end
    let(:provider) do
      resource.provider
    end
    let(:vm_info) do
      {
        'architecture': 'x86_64',
        'config': {
          'image.architecture': 'amd64',
          'image.description': 'Ubuntu focal amd64 (20220131_07:42)',
          'image.os': 'Ubuntu',
          'image.release': 'focal',
          'image.serial': '20220131_07:42',
          'image.type': 'disk-kvm.img',
          'image.variant': 'default',
          'volatile.base_image': '03f7e4ce9be66f4193f6140fb677fbc0fcc5b3aad8383fa618b3c2bac3a5fd1a',
          'volatile.eth0.hwaddr': '00:16:3e:08:b1:33',
          'volatile.last_state.power': 'STOPPED',
          'volatile.uuid': '20dea4dd-946c-455a-abd6-9e3e5fc89bbe',
          'volatile.vsock_id': '101'
        },
        'created_at': '2022-02-02T00:25:11.278956966Z',
        'description': '',
        'devices': {},
        'ephemeral': false,
        'expanded_config': {
          'image.architecture': 'amd64',
          'image.description': 'Ubuntu focal amd64 (20220131_07:42)',
          'image.os': 'Ubuntu',
          'image.release': 'focal',
          'image.serial': '20220131_07:42',
          'image.type': 'disk-kvm.img',
          'image.variant': 'default',
          'limits.cpu.allowance': '200%',
          'volatile.base_image': '03f7e4ce9be66f4193f6140fb677fbc0fcc5b3aad8383fa618b3c2bac3a5fd1a',
          'volatile.eth0.hwaddr': '00:16:3e:08:b1:33',
          'volatile.last_state.power': 'STOPPED',
          'volatile.uuid': '20dea4dd-946c-455a-abd6-9e3e5fc89bbe',
          'volatile.vsock_id': '101'
        },
        'expanded_devices': {
          'eth0': {
            'name': 'eth0',
            'nictype': 'bridged',
            'parent': 'br0',
            'type': 'nic'
          },
          'root': {
            'path': '/',
            'pool': 'default',
            'type': 'disk'
          }
        },
        'last_used_at': '2022-02-09T12:09:59.899639441Z',
        'location': 'none',
        'name': 'vm01',
        'profiles': [
          'default',
        ],
        'project': 'default',
        'stateful': false,
        'status': 'Started',
        'status_code': 102,
        'type': 'virtual-machine'
      }
    end

    describe '.exists?' do
      context 'when not existing' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances']).and_return('[]')
        end
        it 'returns false' do
          expect(provider.exists?).to be false
        end
      end
      context 'when existing' do
        before(:each) do
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/instances']).and_return(
            '[ "/1.0/instances/vm01" ]',
          )
        end
        it 'returns true' do
          expect(provider.exists?).to be true
        end
      end
    end
    describe '.create' do
      context 'when creating' do
        before(:each) do
          expect(provider).to receive(:lxc).with(
            [
              'query', '--wait', '-X', 'POST', '-d',
              {
                'name' => 'vm01',
                'architecture' => 'x86_64',
                'profiles' => ['default'],
                'config' => {
                  'limits.memory' => '2GB',
                },
                'devices' => {},
                'source' => {
                  'type' => 'image',
                  'alias' => 'ubuntu:focal:amd64:default:virtual-machine'
                },
                'type' => 'virtual-machine'
              }.to_json,
              '/1.0/instances'
            ],
          ).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T17:44:39.535002602+02:00',
              'description': 'Creating instance',
              'err': '',
              'id': 'b64c8f92-e6a2-4483-9389-3d6a992b3ba3',
              'location': 'none',
              'may_cancel': false,
              'metadata': {
                'create_instance_from_image_unpack_progress': 'Unpack: 100% (1.96GB/s)',
                'progress': {
                  'percent': '100',
                  'speed': '1960113960',
                  'stage': 'create_instance_from_image_unpack'
                }
              },
              'resources': {
                'instances': [
                  '/1.0/instances/vm01',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T17:44:39.595980938+02:00'
            }.to_json,
          )
          expect(provider).to receive(:lxc).with(['query', '--wait', '-X', 'PUT', '-d', '{"action":"start"}', '/1.0/instances/vm01/state']).and_return(
            {
              'class': 'task',
              'created_at': '2022-02-10T17:48:58.777579208+02:00',
              'description': 'Starting instance',
              'err': '',
              'id': '1a10093b-04e3-4b4d-b41e-63adf5837657',
              'location': 'none',
              'may_cancel': false,
              'metadata': nil,
              'resources': {
                'instances': [
                  '/1.0/instances/vm01',
                ]
              },
              'status': 'Success',
              'status_code': 200,
              'updated_at': '2022-02-10T17:48:58.777579208+02:00'
            }.to_json,
          )
        end
        it 'will not raise any errors' do
          expect { provider.create }.not_to raise_error
        end
      end
    end
  end
end

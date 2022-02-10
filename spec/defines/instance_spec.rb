# frozen_string_literal: true

require 'spec_helper'

describe 'lxd::instance' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe 'with container' do
        let(:pre_condition) { "lxd::image { 'ubuntu:focal:amd64:default:container': ensure => present }" }
        let(:title) { 'ct01' }
        let(:params) do
          {
            'type' => 'container',
            'image' => 'ubuntu:focal:amd64:default:container',
            'state' => 'started',
            'config' => {
              'limits.memory' => '2GB'
            },
            'devices' => {},
            'profiles' => ['default'],
          }
        end

        context 'with ensure => present' do
          let(:params) { super().merge({ 'ensure' => 'present' }) }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__instance('ct01').with(
              'ensure' => 'present',
              'type' => 'container',
              'state' => 'started',
              'image' => 'ubuntu:focal:amd64:default:container',
              'config' => {
                'limits.memory' => '2GB'
              },
              'devices' => {},
              'profiles' => ['default'],
            ).that_requires('Lxd::Image[ubuntu:focal:amd64:default:container]')
          end
        end

        context 'with ensure => absent' do
          let(:params) { super().merge({ 'ensure' => 'absent', 'state' => 'stopped' }) }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__instance('ct01').with(
              'ensure' => 'absent',
              'state' => 'stopped',
            )
          end
        end
      end

      describe 'with virtual-machine' do
        let(:pre_condition) { "lxd::image { 'ubuntu:focal:amd64:default:virtual-machine': ensure => present }" }
        let(:title) { 'vm01' }
        let(:params) do
          {
            'type' => 'virtual-machine',
            'image' => 'ubuntu:focal:amd64:default:virtual-machine',
            'state' => 'started',
            'config' => {
              'limits.memory' => '2GB'
            },
            'devices' => {},
            'profiles' => ['default'],
          }
        end

        context 'with ensure => present' do
          let(:params) { super().merge({ 'ensure' => 'present' }) }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__instance('vm01').with(
              'ensure' => 'present',
              'type' => 'virtual-machine',
              'state' => 'started',
              'image' => 'ubuntu:focal:amd64:default:virtual-machine',
              'config' => {
                'limits.memory' => '2GB'
              },
              'devices' => {},
              'profiles' => ['default'],
            ).that_requires('Lxd::Image[ubuntu:focal:amd64:default:virtual-machine]')
          end
        end

        context 'with ensure => absent' do
          let(:params) { super().merge({ 'ensure' => 'absent', 'state' => 'stopped' }) }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__instance('vm01').with(
              'ensure' => 'absent',
              'state' => 'stopped',
            ).that_comes_before('Lxd::Image[ubuntu:focal:amd64:default:virtual-machine]')
          end
        end
      end
    end
  end
end

# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe 'lxd::container' do # rubocop:disable HashSyntax
  on_supported_os.each do |os, facts|
    describe "on #{os}" do
      let(:facts) { facts }

      describe 'with container' do
        let(:title) { 'container01' }
        let(:params) do
          {
            'config' => {
              'limits.memory' => '2048MB'
            },
            'profiles' => ['default'],
            'instance_type' => 'container',
            'image' => 'debian:buster:amd64:default:container'
          }
        end
        let(:pre_condition) do
          "
          lxd::image { 'debian:buster:amd64:default:container':
            ensure => present
          }
          "
        end

        context 'when ensure => present' do
          let(:params) do
            super().merge(
              {
                'ensure' => 'present',
                'state' => 'started',
              },
            )
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__container('container01').with(
              'ensure' => 'present',
              'state' => 'started',
              'config' => {
                'limits.memory' => '2048MB',
              },
              'devices' => {},
              'profiles' => ['default'],
              'image' => 'debian:buster:amd64:default:container'
            ).that_requires('Lxd::Image[debian:buster:amd64:default:container]')
          end
        end

        context 'when ensure => absent' do
          let(:params) do
            super().merge(
              {
                'ensure' => 'absent',
                'state' => 'stopped',
              },
            )
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__container('container01').with(
              'ensure' => 'absent',
              'state' => 'stopped',
            ).that_comes_before('Lxd::Image[debian:buster:amd64:default:container]')
          end
        end
      end

      describe 'with virtual-machine' do
        let(:title) { 'vm01' }
        let(:params) do
          {
            'config' => {
              'limits.memory' => '2048MB'
            },
            'profiles' => ['default'],
            'instance_type' => 'virtual-machine',
            'image' => 'debian:buster:amd64:default:virtual-machine'
          }
        end
        let(:pre_condition) do
          "
          lxd::image { 'debian:buster:amd64:default:virtual-machine':
            ensure => present
          }
          "
        end
        context 'when ensure => present' do
          let(:params) do
            super().merge(
              {
                'ensure' => 'present',
                'state' => 'started',
              },
            )
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__container('vm01').with(
              'ensure' => 'present',
              'state' => 'started',
              'config' => {
                'limits.memory' => '2048MB',
              },
              'devices' => {},
              'profiles' => ['default'],
              'image' => 'debian:buster:amd64:default:virtual-machine'
            ).that_requires('Lxd::Image[debian:buster:amd64:default:virtual-machine]')
          end
        end

        context 'when ensure => absent' do
          let(:params) do
            super().merge(
              {
                'ensure' => 'absent',
                'state' => 'stopped',
              },
            )
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd__container('vm01').with(
              'ensure' => 'absent',
              'state' => 'stopped',
            ).that_comes_before('Lxd::Image[debian:buster:amd64:default:virtual-machine]')
          end
        end
      end
    end
  end
end

# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe 'lxd' do
  on_supported_os.each do |os, facts|
    describe "on #{os}" do
      let(:facts) { facts }

      describe 'on single node setup' do
        let(:params) do
          {
            'auto_update_interval' => 6,
            'auto_update_interval_ensure' => 'present',
            'core_https_address' => '192.168.0.100:8443',
            'core_https_address_ensure' => 'present',
            'core_trust_password' => 'sekret',
            'core_trust_password_ensure' => 'present'
          }
        end

        it { is_expected.to compile.with_all_deps }

        context 'with ensure => present' do
          let(:params) do
            super().merge(
              {
                'ensure' => 'present',
              },
            )
          end

          context 'when installed from deb package' do
            let(:params) do
              super().merge(
                {
                  'lxd_package_provider' => 'deb',
                },
              )
            end

            it { is_expected.to contain_package('lxd').with_ensure('present') }
          end

          context 'when installed via snap' do
            let(:params) do
              super().merge(
                {
                  'lxd_package_provider' => 'snap',
                },
              )
            end

            context 'and $lxd::manage_snapd is true' do
              let(:params) do
                super().merge(
                  {
                    'manage_snapd' => true,
                  },
                )
              end

              it { is_expected.not_to contain_package('lxd') }
              it { is_expected.to contain_package('snapd').with_ensure('present') }
              it { is_expected.to contain_exec('install lxd') }
            end
            context 'and $lxd::manage_snapd is false' do
              let(:params) do
                super().merge(
                  {
                    'manage_snapd' => false,
                  },
                )
              end

              it { is_expected.not_to contain_package('lxd') }
              it { is_expected.not_to contain_package('snapd') }
              it { is_expected.to contain_exec('install lxd') }
            end
          end

          it do
            is_expected.to contain_lxd_config('global_images.auto_update_interval').with(
              'ensure' => 'present',
              'config' => ['images.auto_update_interval'],
              'value' => 6,
            )
          end
          it do
            is_expected.to contain_lxd_config('global_core.https_address').with(
              'ensure' => 'present',
              'config' => ['core.https_address'],
              'value' => '192.168.0.100:8443',
            )
          end
          it do
            is_expected.to contain_lxd_config('global_core.trust_password').with(
              'ensure' => 'present',
              'config' => ['core.trust_password'],
              'value' => 'sekret',
            )
          end
        end

        context 'with ensure => absent' do
          let(:params) do
            super().merge(
              {
                'ensure' => 'absent',
              },
            )
          end

          context 'when installed from deb package' do
            let(:params) do
              super().merge(
                {
                  'lxd_package_provider' => 'deb',
                },
              )
            end

            it { is_expected.to contain_package('lxd').with_ensure('absent') }
          end

          context 'when installed via snap' do
            let(:params) do
              super().merge(
                {
                  'lxd_package_provider' => 'snap',
                },
              )
            end

            context 'and $lxd::manage_snapd is true' do
              let(:params) do
                super().merge(
                  {
                    'manage_snapd' => true,
                  },
                )
              end

              it { is_expected.not_to contain_package('lxd') }
              it { is_expected.to contain_package('snapd').with_ensure('absent') }
              it { is_expected.to contain_exec('remove lxd') }
            end
            context 'and $lxd::manage_snapd is false' do
              let(:params) do
                super().merge(
                  {
                    'manage_snapd' => false,
                  },
                )
              end

              it { is_expected.not_to contain_package('lxd') }
              it { is_expected.not_to contain_package('snapd') }
              it { is_expected.to contain_exec('remove lxd') }
            end
          end
        end
      end
    end
  end
end

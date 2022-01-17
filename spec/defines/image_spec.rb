# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe 'lxd::image' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'bionic' }

      describe 'with custom image server' do
        let(:params) do
          {
            'repo_url' => 'http://somerepo.url/lxd-images',
            'image_file' => 'bionicimage.tar.gz',
            'image_alias' => 'bionic',
            'pull_from' => 'custom'
          }
        end
        let(:pre_condition) do
          " Exec {
              path => '/usr/bin:/bin:/usr/sbin:/sbin',
            }"
        end

        context 'on ensure => present' do
          it { is_expected.to compile }
          it do
            is_expected.to contain_exec('lxd image present http://somerepo.url/lxd-images/bionicimage.tar.gz')
              .with_command(
                'rm -f /tmp/puppet-download-lxd-image && wget -qO - ' \
                "'http://somerepo.url/lxd-images/bionicimage.tar.gz' " \
                '> /tmp/puppet-download-lxd-image && lxc image import ' \
                "/tmp/puppet-download-lxd-image --alias 'bionic' " \
                '&& rm -f /tmp/puppet-download-lxd-image',
              ).with_unless("lxc image ls -cl --format csv | grep '^bionic$'").with_timeout(600)
          end
        end

        context 'on ensure => absent' do
          let(:params) { super().merge({ 'ensure' => 'absent' }) }

          it { is_expected.to compile }
          it do
            is_expected.to contain_exec('lxd image absent http://somerepo.url/lxd-images/bionicimage.tar.gz')
              .with_command("lxc image rm 'bionic'")
              .with_onlyif("lxc image ls -cl --format csv | grep '^bionic$'")
              .with_timeout(600)
          end
        end
      end

      describe 'with official image server' do
        let(:title) { 'debian:buster' }
        let(:params) do
          {
            'arch' => 'amd64',
            'image_type' => 'container',
            'variant' => 'default',
            'pull_from' => 'official'
          }
        end

        context 'on ensure => present' do
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd_image('debian:buster').with(
              'ensure' => 'present',
              'arch' => 'amd64',
              'repo_url' => 'uk.lxd.images.canonical.com',
              'img_type' => 'container',
              'variant' => 'default',
            )
          end
          it do
            is_expected.not_to contain_exec('lxd image present uk.lxd.images.canonical.com/')
          end
        end

        context 'on ensure => absent' do
          let(:params) do
            super().merge(
              {
                'ensure' => 'absent'
              },
            )
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_lxd_image('debian:buster').with_ensure('absent')
          end
          it do
            is_expected.not_to contain_exec(%r{lxd image absent})
          end
        end
      end
    end
  end
end

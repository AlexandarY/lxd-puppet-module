# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe 'lxd::image', :type => 'define' do # rubocop:disable HashSyntax
  let(:title) { 'bionic' }

  let(:params) do
    {
      'repo_url'    => 'http://somerepo.url/lxd-images',
      'image_file'  => 'bionicimage.tar.gz',
      'image_alias' => 'bionic',
    }
  end

  let(:pre_condition) do
    " Exec {
        path => '/usr/bin:/bin:/usr/sbin:/sbin',
      }"
  end

  context 'ensure present' do
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

  context 'ensure absent' do
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

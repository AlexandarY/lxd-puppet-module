# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe 'lxd::container', :type => 'define' do # rubocop:disable HashSyntax
  let(:title) { 'container01' }

  let(:params) do
    {
      'image' => 'bionic'
    }
  end

  let(:pre_condition) do
    "Exec {
      path => '/usr/bin:/bin:/usr/sbin:/sbin',
    }

    lxd::image { 'bionic':
      repo_url    => 'http://somerepo.url/lxd-images',
      image_file  => 'bionicimage.tar.gz',
      image_alias => 'bionic',
    }"
  end

  context 'ensure present' do
    it { is_expected.to compile }
    it do
      is_expected.to contain_lxd__container('container01').that_requires('Lxd::Image[bionic]')
    end
  end

  context 'ensure absent' do
    let(:params) { super().merge({ 'ensure' => 'absent' }) }

    it do
      is_expected.to contain_lxd__container('container01').that_comes_before('Lxd::Image[bionic]')
    end
  end
end

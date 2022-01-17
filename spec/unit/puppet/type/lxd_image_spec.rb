# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_image) do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'with valid attributes' do
        it 'has to pass successfully' do
          expect(described_class.new(
            {
              # rubocop:disable HashSyntax
              :name => 'debian:buster',
              :repo_url => 'uk.lxd.images.canonical.com',
              :arch => 'amd64',
              :img_type => 'container',
              :variant => 'default',
              # rubocop:enable HashSyntax
            },
          )).not_to raise_error
        end
      end
      describe 'with incorrect' do
        it 'has to fail `arch` validation' do
          expect(described_class.new(
            {
              # rubocop:disable HashSyntax
              :name => 'debian:buster',
              :repo_url => 'uk.lxd.images.canonical.com',
              :arch => 'WRONG',
              :img_type => 'container',
              :variant => 'default',
              # rubocop:enable HashSyntax
            },
          )).to raise_error(%r{WRONG is not a supported architecture!})
        end
        it 'has to fail `img_type` validation' do
          expect(described_class.new(
            {
              # rubocop:disable HashSyntax
              :name => 'debian:buster',
              :repo_url => 'uk.lxd.images.canonical.com',
              :arch => 'amd64',
              :img_type => 'PhysicalHost',
              :variant => 'default',
              # rubocop:enable HashSyntax
            },
          )).to raise_error(%r{PhysicalHost is not a valid img_type!})
        end
        it 'has to fail `variant` validation' do
          expect(described_class.new(
            {
              # rubocop:disable HashSyntax
              :name => 'debian:buster',
              :repo_url => 'uk.lxd.images.canonical.com',
              :arch => 'amd64',
              :img_type => 'container',
              :variant => 'server-wrong',
              # rubocop:enable HashSyntax
            },
          )).to raise_error(%r{server-wrong is not a valid option for variant!})
        end
      end
    end
  end
end

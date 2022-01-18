# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_image).provider(:image) do
  before(:each) do
    @resource = Puppet::Type.type(:lxd_image).new(
      # rubocop:disable HashSyntax
      {
        :name        => 'debian:buster:amd64:default:container',
        :ensure      => 'present',
        :repo_url    => 'images.linuxcontainers.org',
      },
      # rubocop:enable HashSyntax
    )
    @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
  end

  context 'without existing image' do
    before :each do
      expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/images']).and_return('[]')
    end
    it 'will check if image exists and return false' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
    end
  end

  context 'with existing image created by lxc_image' do
    before :each do
      expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/images']).ordered.and_return(
        '[ "/1.0/images/ccebf2ca3a56d0e6c35e2889d26ba82dc533e76e3383e69a30a24448764e62d0" ]',
      )
      expect(described_class).to receive(:lxc).with(
        ['query', '--wait', '-X', 'GET', '/1.0/images/ccebf2ca3a56d0e6c35e2889d26ba82dc533e76e3383e69a30a24448764e62d0'],
      ).ordered.and_return('
        {
          "aliases": [
              {
                  "description": "",
                  "name": "debian:buster:amd64:default:container"
              }
          ],
          "architecture": "x86_64",
          "auto_update": false,
          "cached": false,
          "created_at": "2022-01-15T06:26:55Z",
          "expires_at": "2022-02-14T06:26:55Z",
          "filename": "root.squashfs",
          "fingerprint": "ef578bb723067e810d78b2348c30a02556f7d858d2d4087400bf38cf93251a3d",
          "last_used_at": "0001-01-01T00:00:00Z",
          "profiles": [
              "default"
          ],
          "properties": {
              "architecture": "amd64",
              "description": "Debian buster amd64 (20220115_06:16)",
              "name": "debian-buster-amd64-default-20220115_06:16",
              "os": "debian",
              "release": "buster",
              "serial": "20220115_06:16",
              "variant": "default"
          },
          "public": false,
          "size": 78930604,
          "type": "container",
          "uploaded_at": "2022-01-17T13:36:47.978855797Z"
        }')
    end
    it 'will check for appropriate output' do
      expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
    end
  end

  context 'with existing image imported outside of puppet' do
    # Difference between this and the previous test it that when adding image via `lxc_image`
    # the alias will be set to the type's Title/Name. If imported outside of puppet, this
    # might be missing and we'd need to find other way to validate if it's the same image
    # as otherwise the `lxc import` command might fail on 'fingerprint already exists'
    #
    before :each do
      expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/images']).ordered.and_return(
        '[ "/1.0/images/ccebf2ca3a56d0e6c35e2889d26ba82dc533e76e3383e69a30a24448764e62d0" ]',
      )
      expect(described_class).to receive(:lxc).with(
        ['query', '--wait', '-X', 'GET', '/1.0/images/ccebf2ca3a56d0e6c35e2889d26ba82dc533e76e3383e69a30a24448764e62d0'],
      ).ordered.and_return('
      {
          "aliases": [
              {
                  "description": "",
                  "name": ""
              }
          ],
          "architecture": "x86_64",
          "auto_update": false,
          "cached": false,
          "created_at": "2022-01-15T06:26:55Z",
          "expires_at": "2022-02-14T06:26:55Z",
          "filename": "root.squashfs",
          "fingerprint": "ef578bb723067e810d78b2348c30a02556f7d858d2d4087400bf38cf93251a3d",
          "last_used_at": "0001-01-01T00:00:00Z",
          "profiles": [
              "default"
          ],
          "properties": {
              "architecture": "amd64",
              "description": "Debian buster amd64 (20220115_06:16)",
              "name": "debian-buster-amd64-default-20220115_06:16",
              "os": "debian",
              "release": "buster",
              "serial": "20220115_06:16",
              "variant": "default"
          },
          "public": false,
          "size": 78930604,
          "type": "container",
          "uploaded_at": "2022-01-17T13:36:47.978855797Z"
      }')
    end
    it 'will check for appropriate output' do
      expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
    end
  end

  context 'with retrieving image' do
    before :each do
      expect(described_class).to receive(:lxc).with(['query', '--wait', '-X', 'GET', '/1.0/images']).and_return('[]')
      allow(described_class).to receive(:get_url_paths).with(['lxd.tar.xz', 'root.squashfs'], 'debian:buster', 'amd64', 'default', 'uk.lxd.images.canonical.com').and_return(
        {
          'lxd.tar.xz' => {
            'path' => 'images/debian/buster/amd64/default/20220115_06:16/lxd.tar.xz',
            'sha256' => '224bb693f8296f65ffe5f9ccfe33cc0b2e574ef1e2f732bcc7d7dad611e1404c',
          },
          'root.squashfs' => {
            'path' => 'images/debian/buster/amd64/default/20220115_06:16/rootfs.squashfs',
            'sha256' => 'a8410de5455f5a47ab42afb82e59825ea58ad3bdee22b15f68a92c77d2756a2f',
          },
        },
      )
      allow(described_class).to receive(:download_image).with('uk.lxd.images.canonical.com', '/images/debian/buster/amd64/default/20220115_06:16/lxd.tar.xz', '/tmp/lxd.tar.xz').and_return(nil)
      allow(described_class).to receive(:download_image).with('uk.lxd.images.canonical.com', '/images/debian/buster/amd64/default/20220115_06:16/root.squashfs', '/tmp/root.squashfs').and_return(nil)
      expect(described_class).to receive(:lxc).with(['image', 'import', '/tmp/lxd.tar.xz', '/tmp/root.squashfs', '--alias', 'debian:buster:amd64:default:container']).and_return(nil)
    end
    it 'will create appropriate config' do
      expect(@provider.exists?).to be false # rubocop:todo InstanceVariable
      expect(@provider.create).to eq(nil) # rubocop:todo InstanceVariable
    end
  end

  context 'with ensure absent' do
    before(:each) do
      @resource = Puppet::Type.type(:lxd_image).new(
        {
          # rubocop:disable HashSyntax
          :name        => 'debian:buster:amd64:default:container',
          :ensure      => 'absent',
          :repo_url    => 'images.linuxcontainers.org'
          # rubocop:enable HashSyntax
        },
      )
      @provider = described_class.new(@resource) # rubocop:todo InstanceVariable
    end

    context 'with removing image' do
      before :each do
        expect(described_class).to receive(:lxc).twice.with(['query', '--wait', '-X', 'GET', '/1.0/images']).and_return(
          '[ "/1.0/images/ef578bb723067e810d78b2348c30a02556f7d858d2d4087400bf38cf93251a3d" ]',
        )
        expect(described_class).to receive(:lxc).twice.with(
          ['query', '--wait', '-X', 'GET', '/1.0/images/ef578bb723067e810d78b2348c30a02556f7d858d2d4087400bf38cf93251a3d'],
        ).and_return('
          {
            "aliases": [
                {
                    "description": "",
                    "name": "debian:buster:amd64:default:container"
                }
            ],
            "architecture": "x86_64",
            "auto_update": false,
            "cached": false,
            "created_at": "2022-01-15T06:26:55Z",
            "expires_at": "2022-02-14T06:26:55Z",
            "filename": "root.squashfs",
            "fingerprint": "ef578bb723067e810d78b2348c30a02556f7d858d2d4087400bf38cf93251a3d",
            "last_used_at": "0001-01-01T00:00:00Z",
            "profiles": [
                "default"
            ],
            "properties": {
                "architecture": "amd64",
                "description": "Debian buster amd64 (20220115_06:16)",
                "name": "debian-buster-amd64-default-20220115_06:16",
                "os": "debian",
                "release": "buster",
                "serial": "20220115_06:16",
                "variant": "default"
            },
            "public": false,
            "size": 78930604,
            "type": "container",
            "uploaded_at": "2022-01-17T13:36:47.978855797Z"
          }')
        expect(described_class).to receive(:lxc).with(
          ['query', '--wait', '-X', 'DELETE', '/1.0/images/ef578bb723067e810d78b2348c30a02556f7d858d2d4087400bf38cf93251a3d'],
        ).and_return('
          {
            "class": "task",
            "created_at": "2022-01-17T15:55:08.101397858Z",
            "description": "Deleting image",
            "err": "",
            "id": "a9980bef-2533-4980-bd0c-6698791ea346",
            "location": "lxctest1",
            "may_cancel": false,
            "metadata": null,
            "resources": {
                "images": [
                    "/1.0/images/ef578bb723067e810d78b2348c30a02556f7d858d2d4087400bf38cf93251a3d"
                ]
            },
            "status": "Success",
            "status_code": 200,
            "updated_at": "2022-01-17T15:55:08.101397858Z"
          }
        ')
      end
      it 'will create appropriate config' do
        expect(@provider.exists?).to be true # rubocop:todo InstanceVariable
        expect(@provider.destroy).to eq(nil) # rubocop:todo InstanceVariable
      end
    end
  end
end

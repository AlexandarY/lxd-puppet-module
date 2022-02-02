# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_storage) do
  [:name, :source].each do |param|
    it "has a #{param} parameter" do
      expect(Puppet::Type.type(:lxd_storage).attrtype(param)).to eq(:param)
    end
  end

  [:ensure, :config, :driver].each do |prop|
    it "has a #{prop} property" do
      expect(Puppet::Type.type(:lxd_storage).attrtype(prop)).to eq(:property)
    end
  end
  describe 'dir storage pool' do
    it 'is valid' do
      expect {
        described_class.new(
          name: 'default-dir',
          driver: 'dir',
          description: 'Default dir pool',
          config: {
            'volume.size' => '1GiB'
          },
        )
      }.not_to raise_error
    end
  end
end

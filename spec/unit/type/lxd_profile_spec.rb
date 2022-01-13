# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_profile) do
  [:name].each do |param|
    it "has a #{param} parameter" do
      expect(Puppet::Type.type(:lxd_profile).attrtype(param)).to eq(:param)
    end
  end

  [:ensure, :config, :devices].each do |prop|
    it "has a #{prop} property" do
      expect(Puppet::Type.type(:lxd_profile).attrtype(prop)).to eq(:property)
    end
  end
end

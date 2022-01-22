# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_cluster_member) do
  [:cluster_password, :address, :join_member, :other_members].each do |param|
    it "does not have a #{param} parameter" do
      expect(Puppet::Type.type(:lxd_cluster_member).attrtype(param)).to eq(:param)
    end
  end

  [:ensure, :enabled].each do |prop|
    it "has a #{prop} property" do
      expect(Puppet::Type.type(:lxd_cluster_member).attrtype(prop)).to eq(:property)
    end
  end
end

# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_config) do
  [:config_name, :config].each do |param|
    it "does not have a #{param} parameter" do
      expect(Puppet::Type.type(:lxd_config).attrtype(param)).to eq(:param)
    end
  end

  [:ensure, :value].each do |prop|
    it "has a #{prop} property" do
      expect(Puppet::Type.type(:lxd_config).attrtype(prop)).to eq(:property)
    end
  end
end

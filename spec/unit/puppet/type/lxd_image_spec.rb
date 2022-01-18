# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.

require 'spec_helper'

describe Puppet::Type.type(:lxd_image) do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      [:name, :repo_url].each do |param|
        it "has a #{param} parameter" do
          expect(Puppet::Type.type(:lxd_image).attrtype(param)).to eq(:param)
        end
      end
    end
  end
end

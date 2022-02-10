
require 'spec_helper'

describe Puppet::Type.type(:lxd_instance) do
  [:name, :image, :type].each do |param|
    it "has a #{param} parameter" do
      expect(Puppet::Type.type(:lxd_instance).attrtype(param)).to eq(:param)
    end
  end

  [:ensure, :config, :devices, :state, :profiles].each do |prop|
    it "has a #{prop} property" do
      expect(Puppet::Type.type(:lxd_instance).attrtype(prop)).to eq(:property)
    end
  end
end

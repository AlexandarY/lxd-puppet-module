require 'spec_helper'

describe 'lxd::storage' do
  on_supported_os.each do |os, facts|
    describe "on #{os}" do
      let(:title) { 'default-storage' }
      let(:facts) { facts }
      let(:params) do
        {
          'driver' => 'dir',
          'description' => 'Managed by Puppet',
          'source' => '/opt/data',
          'config' => {
            'volume.size' => '5GB'
          },
        }
      end

      context 'with ensure => present' do
        let(:params) do
          super().merge(
            {
              'ensure' => 'present',
            },
          )
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_lxd__storage('default-storage').with(
            'ensure' => 'present',
            'description' => 'Managed by Puppet',
            'driver' => 'dir',
            'source' => '/opt/data',
            'config' => {
              'volume.size' => '5GB'
            },
          )
        end
      end

      context 'with ensure => absent' do
        let(:params) do
          super().merge(
            {
              'ensure' => 'absent',
            },
          )
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_lxd__storage('default-storage').with_ensure('absent') }
      end
    end
  end
end

require 'spec_helper'

describe 'openvmtools' do

  let(:pre_condition) {
    "include buildenv::kernel"
  }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
    end
  end
end

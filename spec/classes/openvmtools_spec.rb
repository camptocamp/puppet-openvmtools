require 'spec_helper'

describe 'openvmtools' do
  let(:facts) {{
    :lsbdistcodename   => 'wheezy',
    :lsbmajdistrelease => '7',
    :osfamily          => 'Debian',
  }}
  let :pre_condition do
    "Exec { path => '/foo', }"
  end
  it { should compile.with_all_deps }
end

source 'https://rubygems.org'
 
group :development, :test do
  gem 'puppetlabs_spec_helper', :require => false
  gem 'puppet-lint',            :require => false
  gem 'rspec-puppet', :github => 'rodjek/rspec-puppet', :branch => 'master'
  gem 'rspec', '< 3.0.0',       :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

#
# == Class: openvmtools::packages
#
# Required packages to compile openvmtools
#
class openvmtools::packages {
  include ::openvmtools::params
  validate_array($::openvmtools::params::packages)
  package { $::openvmtools::params::packages:
    ensure => installed,
  }
}

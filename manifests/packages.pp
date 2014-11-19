#
# == Class: openvmtools::packages
#
# Required packages to compile openvmtools
#
class openvmtools::packages {

  case $::osfamily {

    RedHat: {
      case $::operatingsystemmajrelease {
        '4','5','6': {
          package { [
            'libicu-devel',
            'procps',
            'libdnet',
            'libdnet-devel',
            'glib2-devel',
            'pam-devel',
            ]:
            ensure => present,
          }
        }
        '7': { }
        default: { fail( "Unsupported version of ${::operatingsystem}" ) }
      }
    }

    Debian: {
      case $::lsbdistcodename {
        lenny,squeeze: {
          package { [
            'open-vm-source',
            'open-vm-tools',
            ]:
            ensure => installed
          }
        }
        wheezy: {
          package { [
            'open-vm-dkms',
            'open-vm-tools',
            ]:
            ensure => installed
          }
        }

        default: {
          fail "Unknown release ${::lsbdistcodename}"
        }
      }
    }

  }
}

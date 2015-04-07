class openvmtools::params {
  case $::osfamily {
    'RedHat': {
      case $::operatingsystemmajrelease {
        '4', '5', '6': {
          # RHEL4 only has an glib2-2.4 version. We must stay with the latest
          # version which doesn't require glib2-2.6.
          $ovt_version = $::operatingsystemmajrelease ? {
            '4'     => '2009.01.21-142982',
            '6'     => '2010.10.18-313025',
            default => '2009.07.22-179896',
          }

          $packages = [
            'libicu-devel',
            'procps',
            'libdnet',
            'libdnet-devel',
            'glib2-devel',
            'pam-devel',
            ]
        }

        '7': {
          $ovt_version = '2009.07.22-179896'

          $packages = []
        }

        default: {
          fail "Unsupported version of ${::operatingsystem}"
        }
      }
    }

    'Debian': {
      $ovt_version = '2009.07.22-179896'

      case $::lsbdistcodename {
        'lenny', 'squeeze': {
          $packages = [ 'open-vm-source', 'open-vm-tools' ]
        }

        'wheezy': {
          $packages = [ 'open-vm-dkms', 'open-vm-tools' ]
        }

        'jessie': {
          $packages = [ 'open-vm-tools-dkms', 'open-vm-tools' ]
        }

        default: {
          fail "Unknown release ${::lsbdistcodename}"
        }
      }
    }

    default: {
      fail "Unsupported OS family '${::osfamily}'"
    }
  }
}

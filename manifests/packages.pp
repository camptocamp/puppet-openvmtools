class openvmtools::packages {

  case $::osfamily {

    RedHat: {
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

    Debian: {
      case $::lsbdistcodename {
        squeeze: {
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

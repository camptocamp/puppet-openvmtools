class openvmtools::packages {
  
  case $operatingsystem {

    RedHat: {
      package { [
        "libicu-devel",
        "procps",
        "libdnet",
        "libdnet-devel",
        "glib2-devel",
        "pam-devel",
        ]:
        ensure => present,
      }
    }

    Debian: {
      package { [
        "open-vm-source",
        "open-vm-tools",
        ]:
        ensure => installed
      }
    }
  }
}

#
# == Class: openvmtools
#
# open-vm-tools is the GPL version of the (in)famous vmware-tools. This project
# is maintained by vmware inc. http://open-vm-tools.sourceforge.net/
#
# Here are the details that led to this not so good solution. Starting point:
# http://open-vm-tools.wiki.sourceforge.net/Distro+Package+Status
#
#- CentOS made packages, but they are only available for the latest kernel.
#  Building and maintaining packages for each kernel release we happen to run
#  would be a lot of work. http://people.centos.org/~hughesjr/open-vm-tools/
#- OpenSuSE maintains their own RPMs, which are not compatible with
#  redhat/fedora.
#  https://build.opensuse.org/project/show?project=Virtualization%3AVMware
#- Folks have built various packages for redhat/centos/fedora but unfortunately
#  none seems to be seriously maintained. Furthermore, they mostly seems to be
#  desktop-oriented (dependencies on xorg, gnome, etc, to improve mouse/keybord
#  management).
#- Fedora's policy forbids non-kernel.org kernel modules.
#  https://bugzilla.redhat.com/show_bug.cgi?id=294341
#- EPEL repository inherits this policy.
#- kernel developers are reluctant to include vmware modules upstream,
#  claiming they are not well written and shouldn't even need to exist.
#  http://lkml.org/lkml/2008/9/8/130
#  http://article.gmane.org/gmane.linux.redhat.fedora.devel/95146
#- Developers need to sign a "contributor agreement" to be able to contribute
#  code to open-vm-tools, in a way which would help inclusion in the kernel.
#  http://article.gmane.org/gmane.linux.redhat.fedora.devel/95149
#- On the other hand, debian has a convenient package available in "contrib".
#  http://packages.debian.org/lenny/open-vm-tools
#
class openvmtools (
  $ovt_version = $openvmtools::params::ovt_version,
  $ovt_src_url = 'switch.dl.sourceforge.net/sourceforge/open-vm-tools',
) inherits ::openvmtools::params {

  include ::openvmtools::packages

  case $::osfamily {

    'RedHat': {
      case $::operatingsystemmajrelease {
        '4','5','6': {

          # curiously open-vm-tools build system links to a non-existing file...
          $file_path = $::architecture ? {
            'x86_64'  => '/usr/lib64/libdnet.1',
            default => '/usr/lib/libdnet.1',
          }
          file { 'libdnet.1':
            ensure  => 'libdnet.so',
            path    => $file_path,
            require => Package['libdnet'],
          }

          $file_source = $::operatingsystemmajrelease ? {
            '4'     => 'puppet:///modules/openvmtools/vmware-guest.init.guestd',
            default => 'puppet:///modules/openvmtools/vmware-guest.init.vmtoolsd',
          }
          file { '/etc/init.d/open-vm-tools':
            mode    => '0755',
            owner   => root,
            group   => root,
            source  => $file_source,
            require => Exec['install open-vm-tools'],
          }

          file { '/usr/local/sbin/install-open-vm-tools.sh':
            mode    => '0755',
            owner   => root,
            group   => root,
            content => template('openvmtools/install-open-vm-tools.sh.erb'),
          }

          file { '/etc/vmware-tools/open-vm-tools.version':
            content => "# This file is managed by puppet. DO NOT EDIT !\n${ovt_version}\n",
            require => Exec['install open-vm-tools'],
          }

          service { 'open-vm-tools':
            ensure    => running,
            require   => [
              File['/etc/init.d/open-vm-tools'],
              Exec['install open-vm-tools'],
              Service['vmware-tools']
              ],
            enable    => true,
            hasstatus => true,
          }

          exec { 'install open-vm-tools':
            command => "/usr/local/sbin/install-open-vm-tools.sh ${ovt_version}",
            unless  => "/usr/bin/test -f /lib/modules/${::kernelrelease}/kernel/drivers/misc/vmsync.ko && grep -q ${ovt_version} /etc/vmware-tools/open-vm-tools.version",
            require => [File['/usr/local/sbin/install-open-vm-tools.sh'], Class['buildenv::kernel'], Class['openvmtools::packages'], Class['buildenv::c']],
            notify  => Service['open-vm-tools'],
            timeout => 300,
            path    => $::path,
          }
        }

        default: {
          package{['open-vm-tools']:
            ensure => present,
          }
          service{ 'vmtoolsd':
            ensure => running,
            enable => true,
          }
        }

      }
    }

    'Debian': {

      case $::lsbdistcodename {
        'squeeze','lenny': {
          package { ["open-vm-modules-${::kernelrelease}"]:
            ensure  => installed,
            require => Exec['install open-vm-modules'],
          }

          exec { 'install open-vm-modules':
            command => 'module-assistant --text-mode auto-install open-vm-source',
            require => [
              Class['openvmtools::packages'],
              Class['buildenv::kernel']
              ],
            unless  => "dpkg -s open-vm-modules-${::kernelrelease} | grep '^Status: install ok installed'",
            path    => $::path,
          }
        } # squeeze

        'wheezy': {

          exec { 'install open-vm-modules':
            command => 'module-assistant --text-mode auto-install open-vm-dkms',
            require => [
              Class['openvmtools::packages'],
              Class['buildenv::kernel']
              ],
            unless  => "dpkg -s open-vm-dkms | grep '^Status: install ok installed'",
            path    => $::path,
          }
        } # wheezy

        'jessie', 'trusty', 'xenial': {

          exec { 'install open-vm-modules':
            command => 'module-assistant --text-mode auto-install open-vm-tools-dkms',
            require => [
              Class['openvmtools::packages'],
              Class['buildenv::kernel']
              ],
            unless  => "dpkg -s open-vm-tools-dkms | grep '^Status: install ok installed'",
            path    => $::path,
          }
        } # jessie/trusty/xenial

        default: {
          fail "Unsupported release ${::lsbdistcodename}"
        }
      }

      $service_pattern = $::lsbdistcodename ? {
        'lenny'   => 'vmware-guestd --background',
        'squeeze' => 'vmtoolsd',
        'wheezy'  => 'vmtoolsd',
        'jessie'  => 'vmtoolsd',
        'trusty'  => 'vmtoolsd',
        'xenial'  => 'vmtoolsd',
      }
      service { 'open-vm-tools':
        ensure    => running,
        enable    => true,
        hasstatus => false,
        pattern   => $service_pattern,
        require   => [
          Class['openvmtools::packages'],
          Exec['install open-vm-modules'],
          Service['vmware-tools']
          ],
      }
    }

    default: {
      fail "Unsupported OS family: ${::osfamily}"
    }

  } # end case $::osfamily

  # ensure vmware-tools is not running, if it happens to be installed.
  service { 'vmware-tools':
    ensure    => stopped,
    enable    => false,
    hasstatus => false,
  }


}

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
class openvmtools {
  include openvmtools::packages

  case $operatingsystem {

    RedHat: {

      # RHEL4 only has an glib2-2.4 version. We must stay with the latest
      # version which doesn't require glib2-2.6.
      $ovt_version = $openvmtools_version ? { 
	      "" => $lsbmajdistrelease ? {
          "4"     => "2009.01.21-142982",
          "6"     => "2010.10.18-313025",
          default => "2009.07.22-179896",
        },
        default => $openvmtools_version,
      }

      # curiously open-vm-tools build system links to a non-existing file...
      file { "libdnet.1":
        ensure => "libdnet.so",
        path => $architecture ? {
          x86_64 => "/usr/lib64/libdnet.1",
          default => "/usr/lib/libdnet.1",
        },
        require => Package["libdnet"],
      }

      file { "/etc/init.d/open-vm-tools":
        mode => 0755,
        owner => root,
        group => root,
        source => $lsbmajdistrelease ? {
          "4"     => "puppet:///modules/openvmtools/vmware-guest.init.guestd",
          default => "puppet:///modules/openvmtools/vmware-guest.init.vmtoolsd",
        },
        require => Exec["install open-vm-tools"],
      }

      file { "/usr/local/sbin/install-open-vm-tools.sh":
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/openvmtools/install-open-vm-tools.sh",
      }

      file { "/etc/vmware-tools/open-vm-tools.version":
        content => "# This file is managed by puppet. DO NOT EDIT !\n$ovt_version\n",
        require => Exec["install open-vm-tools"],
      }

      service { "open-vm-tools":
        require => [File["/etc/init.d/open-vm-tools"], Exec["install open-vm-tools"], Service["vmware-tools"]],
        ensure => running,
        enable => true,
        hasstatus => true,
      }

      exec { "install open-vm-tools":
        command => "/usr/local/sbin/install-open-vm-tools.sh $ovt_version",
        unless => "/usr/bin/test -f /lib/modules/$kernelrelease/kernel/drivers/misc/vmsync.ko && grep -q $ovt_version /etc/vmware-tools/open-vm-tools.version",
        require => [File["/usr/local/sbin/install-open-vm-tools.sh"], Class["buildenv::kernel"], Class["openvmtools::packages"], Class["buildenv::c"]],
        notify => Service["open-vm-tools"],
        timeout => 300,
      }

    }

    Debian: {

      package { ["open-vm-modules-$kernelrelease"]:
        ensure => installed,
        require => Exec["install open-vm-modules"],
      }

      exec { "install open-vm-modules":
        command => "module-assistant --text-mode auto-install open-vm-source",
        require => [Class["openvmtools::packages"], Class["buildenv::kernel"]],
        unless  => "dpkg -s open-vm-modules-${kernelrelease} | grep '^Status: install ok installed'",
      }

      service { "open-vm-tools":
        ensure => running,
        enable => true,
        hasstatus => false,
        pattern => "vmware-guestd --background",
        require => [Class["openvmtools::packages"], Package["open-vm-modules-$kernelrelease"], Exec["install open-vm-modules"], Service["vmware-tools"]],
      }
    }

  } # end case $operatingsystem

  # ensure vmware-tools is not running, if it happens to be installed.
  service { "vmware-tools":
    ensure => stopped,
    enable => false,
  }


}

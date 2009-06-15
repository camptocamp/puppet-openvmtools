class openvmtools {

####
# open-vm-tools est la version GPL des infâmes vmware-tools. Ce projet est
# maintenu par vmware inc. http://open-vm-tools.sourceforge.net/
#
# Voici le processus de réflexion qui a amené à cette solution temporaire qui
# va durer. Point de départ:
# http://open-vm-tools.wiki.sourceforge.net/Distro+Package+Status
#
# - CentOS a des paquets disponibles, mais uniquement compilés contre la
#   dernière version de kernel en date. Backporter le package et le recompiler
#   pour toutes les différentes variantes de kernel utilisés serait un gros
#   boulot - http://people.centos.org/~hughesjr/open-vm-tools/

# - Opensuse a fait un rpm, complètement spécifique à opensuse, difficilement
#   transposable à redhat.
#   https://build.opensuse.org/project/show?project=Virtualization%3AVMware
#
# - Des initiatives individuelles pour redhat/centos/fedora apparaissent ici et
#   là, mais aucune ne semble sérieusement maintenue, d'autant moins pour RHEL.
#   De plus, les paquets sont plutôt orientés "desktop" (dépendances sur Xorg,
#   gnome, etc) pour améliorer la gestion souris/clavier.
#
# - Fedora ne permet pas les modules kernel hors kernel upstream
#   https://bugzilla.redhat.com/show_bug.cgi?id=294341
#
# - Le repository EPEL hérite de cette policy
#
# - les développeurs kernel rechignent à intégrer ces modules vmware dans le
#   kernel car ils sont mal codés et ne devraient même pas exister.
#   http://lkml.org/lkml/2008/9/8/130
#   http://article.gmane.org/gmane.linux.redhat.fedora.devel/95146
#
# - En plus, il faut signer un "contributor agreement" louche pour contribuer à
#   faire avancer open-vm-tools dans le sens d'une inclusion dans le kernel.
#   http://article.gmane.org/gmane.linux.redhat.fedora.devel/95149
#
# - En revanche, debian a déjà un paquet dans contrib.
#   http://packages.debian.org/lenny/open-vm-tools
#
# Bref, affaire à suivre...
#

  case $operatingsystem {

    RedHat: {

      $ovt_version = "2008.11.18-130226"

      package { ["gcc", "gcc-c++", "libicu-devel", "kernel-devel-${kernelrelease}", "procps", "libdnet", "libdnet-devel"]:
        ensure => present,
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
        source => "puppet:///openvmtools/vmware-guest.init",
      }

      file { "/usr/local/sbin/install-open-vm-tools.sh":
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///openvmtools/install-open-vm-tools.sh",
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

      service { "vmware-tools":
        ensure => stopped,
        enable => false,
      }

      exec { "install open-vm-tools":
        command => "/usr/local/sbin/install-open-vm-tools.sh $ovt_version",
        unless => "/usr/bin/test -f /lib/modules/$kernelrelease/kernel/drivers/misc/vmmemctl.ko && grep -q $ovt_version /etc/vmware-tools/open-vm-tools.version",
        require => [File["/usr/local/sbin/install-open-vm-tools.sh"], Package["gcc"], Package["gcc-c++"], Package["libicu-devel"], Package["kernel-devel-${kernelrelease}"], Package["procps"], Package["libdnet"], Package["libdnet-devel"]],
        notify => Service["open-vm-tools"],
      }

    }

    Debian: { #BUG: pas testé !!!

      package { ["open-vm-source", "open-vm-tools"]:
        ensure => installed
      }

      package { ["open-vm-modules-$kernelrelease"]:
        ensure => installed,
        require => Exec["install open-vm-modules"],
      }

      exec { "install open-vm-modules":
        command => "/usr/bin/module-assistant auto-install open-vm-source",
        require => Package["open-vm-source"],
      }

      service { "open-vm-tools":
        ensure => running,
        require => Package["open-vm-tools"],
      }
    }


  } # end case $operatingsystem

}

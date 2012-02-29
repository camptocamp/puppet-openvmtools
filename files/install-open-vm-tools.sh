#!/bin/bash
# file managed by puppet

#####
# This script grabs, builds and installs a definied version of open-vm-tools
#
# dependencies:
# gcc gcc-c++ libicu-devel kernel-devel-$(uname -r) procps libdnet libdnet-devel

if [ $# -ne 1 ]; then
  echo usage $0 version
  exit 1
fi

# procps not detected on RH4. See
# http://www.mail-archive.com/open-vm-tools-devel@lists.sourceforge.net/msg00013.html
if $(lsb_release -c | grep -q Nahant); then
  add_confopts=" --without-procps "
fi

# check if process is running, stop it if so
if [ -f /etc/init.d/open-vm-tools ]; then
  /etc/init.d/open-vm-tools stop
fi

MIRROR="switch.dl.sourceforge.net"
VER=$1
WORKDIR=$(mktemp -d)
BUILDLOG=/tmp/open-vm-tools-${VER}-build.log

wget -qP $WORKDIR http://${MIRROR}/sourceforge/open-vm-tools/open-vm-tools-${VER}.tar.gz > /dev/null
tar -C $WORKDIR -xzf $WORKDIR/open-vm-tools-${VER}.tar.gz || exit 1

# bugfix for version 2009.07.22-179896. See
# https://sourceforge.net/tracker/index.php?func=detail&aid=2854490&group_id=204462&atid=989708
if [ "$VER" == "2009.07.22-179896" ]; then
  wget -nv -O $WORKDIR/open-vm-tools-${VER}/patch-989708.patch "https://sourceforge.net/tracker/download.php?group_id=204462&atid=989708&file_id=342259&aid=2854490" >$BUILDLOG 2>&1 || exit 1
  (cd $WORKDIR/open-vm-tools-${VER}/ && patch -p1 < $WORKDIR/open-vm-tools-${VER}/patch-989708.patch >> $BUILDLOG 2>&1) || exit 1
fi

(cd $WORKDIR/open-vm-tools-${VER}/ && ./configure --without-gtk2 --without-x --without-gtkmm --without-pam $add_confopts >> $BUILDLOG 2>&1) || exit 1
make -C $WORKDIR/open-vm-tools-${VER}/ >> $BUILDLOG 2>&1 || exit 1
make -C $WORKDIR/open-vm-tools-${VER}/ install >> $BUILDLOG 2>&1 || exit 1

rm -fr $WORKDIR

exit 0

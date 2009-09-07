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

MIRROR="switch.dl.sourceforge.net"
#VER="2008.11.18-130226"
VER=$1
WORKDIR=$(mktemp -d)
BUILDLOG=/tmp/open-vm-tools-${VER}-build.log

wget -qP $WORKDIR http://${MIRROR}/sourceforge/open-vm-tools/open-vm-tools-${VER}.tar.gz > /dev/null
tar -C $WORKDIR -xzf $WORKDIR/open-vm-tools-${VER}.tar.gz || exit 1
(cd $WORKDIR/open-vm-tools-${VER}/ && ./configure --without-x $add_confopts > $BUILDLOG 2>&1) || exit 1
make -C $WORKDIR/open-vm-tools-${VER}/ >> $BUILDLOG 2>&1 || exit 1
make -C $WORKDIR/open-vm-tools-${VER}/ install >> $BUILDLOG 2>&1 || exit 1

rm -fr $WORKDIR

exit 0

#!/bin/bash
set -euo pipefail

ARCH=`dpkg-architecture -q DEB_HOST_ARCH`
DISTRO=`lsb_release -cs`
VENDOR=`lsb_release -is`
CHROOT=dirtbike-$DISTRO-$ARCH
CHROOT_DIR=/var/lib/schroot/chroots/$CHROOT
INCLUDES=eatmydata,gdebi-core,software-properties-common

if [ "$VENDOR" = "Ubuntu" ]
then
    UNIONTYPE=overlayfs
else
    UNIONTYPE=overlay
fi

echo "Creating schroot $CHROOT"

cat > /etc/schroot/chroot.d/$CHROOT<<EOF
[$CHROOT]
description=$CHROOT
groups=sbuild,root
root-groups=sbuild,root
# Uncomment these lines to allow members of these groups to access
# the -source chroots directly (useful for automated updates, etc).
#source-root-users=sbuild,root
#source-root-groups=sbuild,root
type=directory
profile=default
command-prefix=eatmydata
union-type=$UNIONTYPE
directory=$CHROOT_DIR

source-root-users=root,sbuild,admin
source-root-groups=root,sbuild,admin
preserve-environment=false
EOF

mkdir -p $CHROOT_DIR
debootstrap --include=$INCLUDES $DISTRO $CHROOT_DIR

# On Ubuntu chroots, make sure universe is enabled.

if [ "$VENDOR" = "Ubuntu" ]
then
    schroot -u root -c source:$CHROOT -- add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ $DISTRO universe"
fi
schroot -u root -c source:$CHROOT -- apt-get update

# Try to install Python 3.5, which may or may not be available in the chroot
# depending on its version.  It's okay if this fails.
schroot -u root -c source:$CHROOT -- apt-get install -y --force-yes python3.5 || echo "Python 3.5 is not available... skipping"

echo "schroot $CHROOT is ready"

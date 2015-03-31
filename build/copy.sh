#!/bin/bash

BUILDID=$1
BRANCH=$2	# Unused for now

umask 0022
cd build/openxt
cp git_heads build-output/ext-dev-${BUILDID}-${BRANCH}/git_heads
cp srcrevs build-output/ext-dev-${BUILDID}-${BRANCH}/srcrevs
./do_build.sh -i $BUILDID -s xctools,ship,extra_pkgs,copy,packages_tree
ret=$?
if [ $ret -ne 0 ]; then
	echo Failed
	exit $ret
fi
echo The build is done
#date=`date +%s`
#mkdir /home/build/${date}
#cp build/openxt/build-output/openxt-dev--master/iso/installer.iso /home/build/${date}/installer.iso

#rm -rf /home/storage/build/last_build
#mv build /home/storage/build/last_build
#rm -rf build


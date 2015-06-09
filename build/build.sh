#!/bin/bash -ex

BUILDID=$1
BRANCH=$2
LAYERS=$3
OVERRIDES=$4
ISSUE=$5

do_overrides () {
    for trip in $OVERRIDES; do
        name=$(echo $trip | cut -f 1 -d ':')
        git=$(echo $trip | cut -f 2 -d ':')
        branch=$(echo $trip | cut -f 3 -d ':')
        
        rm -rf git/$name.git
        git clone --mirror git://$git/$name git/$name.git
        #Copyright (c) Jed
        pushd git/$name.git
        git branch tmp
        git symbolic-ref HEAD refs/heads/tmp
        git branch -m master originalmaster
        git branch master $branch
        popd
    done
}

umask 0022
#It is against policy to set both $ISSUE and $OVERRIDES in the buildbot ui
if [[ $ISSUE != 'None' && $OVERRIDES == 'None' ]]; then
    OVERRIDES=$( ./build_for_issue.sh $ISSUE )
else
    echo "Cannot pass both a Jira ticket and custom repository overrides to build from."
    exit -1
fi
OFS=$IFS
IFS=','
do_overrides
IFS=$OFS
cd build
#Extra case for openxt override
git clone /home/build/builder/build/git/openxt.git
cd openxt
cp -r ../../certs .
mv /tmp/git_heads_$BUILDID git_heads
cp example-config .config
cat <<EOF >> .config
NAME_SITE="ext"
OPENXT_MIRROR="http://buildmaster/mirror"
OE_TARBALL_MIRROR="http://buildmaster/mirror"
OPENXT_GIT_MIRROR="/home/build/builder/build/git"
OPENXT_GIT_PROTOCOL="file"
REPO_PROD_CACERT="/home/build/builder/build/certs/prod-cacert.pem"
REPO_DEV_CACERT="/home/build/builder/build/certs/dev-cacert.pem"
REPO_DEV_SIGNING_CERT="/home/build/builder/build/certs/dev-cacert.pem"
REPO_DEV_SIGNING_KEY="/home/build/builder/build/certs/dev-cakey.pem"
WIN_BUILD_OUTPUT="buildbot@192.168.0.10:/home/build/win"
SYNC_CACHE_OE=192.168.0.10:/home/build/oe
BUILD_RSYNC_DESTINATION=127.0.0.1:/home/storage/builds
NETBOOT_HTTP_URL=http://192.99.200.146:81/builds
BRANCH=$BRANCH
EOF
./do_build.sh -i $BUILDID -s setupoe,sync_cache
if [[ $LAYERS != 'None' ]]; then
	../../engage_layers.sh $LAYERS
fi
./do_build.sh -i $BUILDID | tee build.log
ret=${PIPESTATUS[0]}
cd -
cd -

exit $ret

#!/bin/bash -x

BRANCH=$1
OVERRIDES=$2
OFS=$IFS
IFS=','
XOE_FLAG="0"
OXT_FLAG="0"

function do_overrides () {
	name=$1
	gitr=$2
	branch=$3
	IFS=$OFS
	srcrev="$( git ls-remote git://$gitr/$name.git $branch | cut -f1 )";
	files=`grep -ilrF $name'.git' build/repos/xenclient-oe/`
	for file in $files;
	do
		recipe_nm="${file##*/}" #Strip leading path
		short_nm="${recipe_nm%_*}" #Strip "_git.bb"
		short_nm="${short_nm%.*}" #Strip ".bb"
		if [ $short_nm == "dm-agent" ] || [ $short_nm == "dm-wrapper" ];
   		then 
        		echo "SRCREV_pn-$short_nm-stubdom=\"$srcrev\"" >> build/conf/local.conf;
	  	fi  
		if [ $short_nm == "xenclient-rpcgen" ];
   		then 
	        	echo "SRCREV_pn-$short_nm-native=\"$srcrev\"" >> build/conf/local.conf;
        	    	echo "OPENXT_GIT_MIRROR_pn-$short_nm-native=\"$gitr\"" >> build/conf/local.conf
			echo "OPENXT_GIT_PROTOCOL_pn-$short_nm-native=\"git\"" >> build/conf/local.conf
			echo "OPENXT_BRANCH_pn-$short_nm-native=\"$branch\"" >> build/conf/local.conf
	    fi  
        #We've cloned into xenclient-oe already.
    	if [ ! $name == "xenclient-oe" ];
	    then
			if [ $gitr == "github.com/openxt" ];
			then
	            #Add the overriden variable for the recipe to local.conf
            	echo "SRCREV_pn-$short_nm=\"$srcrev\"" >> build/conf/local.conf
			else
            	echo "SRCREV_pn-$short_nm=\"$srcrev\"" >> build/conf/local.conf
            	echo "OPENXT_GIT_MIRROR_pn-$short_nm=\"$gitr\"" >> build/conf/local.conf
				echo "OPENXT_GIT_PROTOCOL_pn-$short_nm=\"git\"" >> build/conf/local.conf
				echo "OPENXT_BRANCH_pn-$short_nm=\"$branch\"" >> build/conf/local.conf
			fi
        fi
	done
	OFS=$IFS
	IFS=','
}

function do_srcrev_rec () {
	name=$1
	gitr=$2
	branch=$3

	srcrev="$( git ls-remote git://$gitr/$name.git $branch | cut -f1 )";
	echo $name':'$srcrev >> srcrevs
}

#Override all upstream repos first, then do custom repos
while read repos ;
do
	do_overrides $repos github.com/openxt master
	if [[ ! $OVERRIDES == *$repos* ]];
	then
		do_srcrev_rec $repos github.com/openxt master
	fi
done < ../../all_repos

#Room for expansion here, support branches for custom repos.
if [[ ! $OVERRIDES == "None" ]];
then
	for trip in $OVERRIDES;
	do
		REPO_NAME=`echo $trip | cut -f 1 -d ':'` 
		REPO_GIT=`echo $trip | cut -f 2 -d ':'`
		REPO_BRANCH=`echo $trip | cut -f 3 -d ':'`
		do_overrides $REPO_NAME $REPO_GIT $REPO_BRANCH
		if [[ $REPO_NAME == "xenclient-oe" ]]; then
			XOE_FLAG=1
		fi
		if [[ $REPO_NAME == "openxt" ]]; then
			OXT_FLAG=1
		fi
		do_srcrev_rec $REPO_NAME $REPO_GIT $REPO_BRANCH
	done
fi

if [[ $XOE_FLAG == "0" ]]; then
	do_srcrev_rec xenclient-oe github.com/openxt master
fi

if [[ $OXT_FLAG == "0" ]]; then
	do_srcrev_rec openxt github.com/openxt master
fi

IFS=$OFS


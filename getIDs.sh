#!/bin/bash
getent=$(which getent)
getID=$(which id)
wbinfo=$(which wbinfo)

domainUIDs=250000

if [ -z "$1" ]; then
	echo "must supply a username!"
	exit 1
fi

# get the username from the command line
xNAME=$1

# let's get the UID and see if this is a domain user
xUID=$($getID -u $xNAME)
if [ "$?" -ne "0" ]; then
	echo "can't find user $xNAME"
	exit 1
fi

domain_user=0
if [ "$xUID" -gt $domainUIDs ]; then
	echo "$xNAME (uid=$xUID) is a domain user"
	domain_user=1
else
	echo "$xNAME (uid=$xUID) is regular unix user"
fi

# make sure the user exists
zNAME=$("$getent" passwd "$xNAME")
if [ ! $? -eq 0 ]; then
	echo "can't find user $xNAME"
	exit 1
fi

# get the SID of the user
if [ "$domain_user" -eq 1 ]; then
	xSID=$("$wbinfo" -n "$xNAME" | awk '{ print $1 }')
	#echo "domain SID=$xSID"
fi

if [ $domain_user -eq 1 ]; then
	# get the generated UID for the SID, (unix format uid)
	xUID=$("$wbinfo" -S $xSID);
	#echo "UNIX UID=$xUID"


	#xtest=$(wbinfo --sids-to-unix-ids "$xSID")
	#echo "$xtest"

	echo "Getting user information for $xNAME (ad uid=$xUID) - ($xSID)"
	echo " groups as seen by winbind"
	# create an array
	declare -A userGroups
	oldIFS=$oldIFS
	IFS=$'\n'
	uGIDS=$(wbinfo --user-groups "$xNAME")
	for uGID in $uGIDS; do
		gSID=$(wbinfo -G $uGID)
		#gNAME=$(wbinfo --sid-to-name "$gSID" | awk '{ print $1 }')
		gData=$(wbinfo --sids-to-unix-ids "$gSID")
		#echo "$gData"
		gSID=$(echo $gData | awk '{ print $1 }')
		dGID=$(echo "$gData" | awk '{ print $4 }')
		gNAME=$(wbinfo --gid-info "$uGID" | awk -F':' '{print $1}')

		echo "    $gNAME (u-GID=$uGID) (d-GID=$dGID) (g-SID=$gSID) "
	done
fi

# get a numerical list of groups (as seen my unix) this user belongs to
#uGIDS=$(wbinfo -r "$xNAME")
#echo $uGIDs
#oldIFS=$oldIFS
#IFS=$'\n'
#for uGROUP in $uGIDS; do
#	gNAME=$(wbinfo --gid-info "$uGROUP")
#	echo "group=$gNAME uGROUP=$uGROUP"
#done

#wbinfo --user-groups aaron
#3000018
#100
#3000006
#3000008
#3000021
#3000005
#3000009
#3000000

#wbinfo -G 100
#S-1-5-21-648430947-3611973424-698436271-513

#wbinfo --user-domgroups S-1-5-21-648430947-3611973424-698436271-1104
#S-1-5-21-648430947-3611973424-698436271-513
#S-1-5-21-648430947-3611973424-698436271-519
#S-1-5-21-648430947-3611973424-698436271-512
#S-1-5-21-648430947-3611973424-698436271-1107

#wbinfo --sids-to-unix-ids S-1-5-21-648430947-3611973424-698436271-519
#S-1-5-21-648430947-3611973424-698436271-519 -> uid/gid 3000006

#wbinfo --unix-ids-to-sids=u243201104
#S-1-22-1-243201104

#wbinfo --unix-ids-to-sids=g243200513
#S-1-5-21-648430947-3611973424-698436271-513

#wbinfo --sids-to-unix-ids=S-1-22-1-243201104
#S-1-22-1-243201104 -> uid 243201104

#wbinfo --name-to-sid 2CHESTER\\Domain\ Admins
#S-1-5-21-648430947-3611973424-698436271-512 SID_DOM_GROUP (2)

#wbinfo --sid-to-name S-1-5-21-648430947-3611973424-698436271-512
#2CHESTER\Domain Admins 2

#getent group 243201102
#dnsadmins:*:243201102:

#getent passwd aaron
#aaron:*:243201104:243200513:aaron:/home/2CHESTER.COM/aaron:/bin/bash

# get a numerical list of groups (as seen by AD) this user belongs to
xGROUPS=$("$getID" -G "$xNAME")

echo -e
echo " groups as seen by id -G $xNAME"
IFS=$' '
for xGROUP in $xGROUPS; do
	gSID=$(wbinfo -G "$xGROUP")
	gData=$(wbinfo --sids-to-unix-ids "$gSID")
	iName=$(getent group "$xGROUP" | awk -F':' '{print $1}')
	gSID=$(echo $gData | awk '{ print $1 }')
	gGID=$(echo "$gData" | awk '{ print $4 }')
	echo "    $iName (gSID=$gSID) (gGID=$gGID)"

done
#IFS=$oldIFS

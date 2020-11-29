#!/bin/bash

set -x

# check variables are set
test -z "$AGENT_USER" && exit -1
test -z "$TARGET_HOST" && exit -1

# run some other script before, to refresh input data
#./btrfs_mounts/update.sh || exit -1

#
# Prepare version control
#

git fetch origin master
git checkout master
git pull

#
#  Execute
#

ALL_MOUNTS=$(ls $PWD/btrfs_mounts/${TARGET_HOST}/*)

cd "$(dirname "$0")" || exit -1

for MOUNT in ${ALL_MOUNTS[@]}; do
  head -1 ${MOUNT} | while read MOUNTPOINT; do
    sudo btrfs subvolume list ${MOUNTPOINT} \
	| egrep '^ID [0-9]+ gen [0-9]+ top level [0-9]+ path .*' \
	| while read LINE; do
	  SUB_PATH=$(echo $LINE | cut -d" " -f9-)
	  SUB_MOUNT=$(realpath "${MOUNTPOINT}/${SUB_PATH}")
	  if [ -d "${SUB_MOUNT}" ]; then
	    echo ${SUB_MOUNT};
	  fi
	  done \
	| while read LINE; do
      sudo btrfs subvolume show "${LINE}" \
      | tr '\n' ';' \
      | sed -e 's/\s\+/ /g' \
      | sed -e 's/;\s\+/;/g' \
      | egrep ';UUID: .*;' \
      | egrep ';Parent UUID: .*;' \
      | egrep ';Received UUID: .*;' \
      | egrep ';Flags: .*;' \
      | while read LINE2; do
          echo "Mount: ${MOUNTPOINT};Dir: ${LINE};RelDir: ${LINE2}"
	    done
      done
  done
done > "${TARGET_HOST}.txt"
git add "${TARGET_HOST}.txt"

#
#  Commit and Push
#

git commit -a -m "$(basename "$0"), $TARGET_HOST, $(date)"
git pull --rebase=true
git push

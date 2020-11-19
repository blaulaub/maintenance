#!/bin/bash

# check variables are set
test -z "$AGENT_USER" && exit -1
test -z "$TARGET_HOST" && exit -1

#
# Prepare version control
#

git fetch origin master
git checkout master

#
#  Execute
#

ALL_MOUNTS="$PWD/all_mounts/$TARGET_HOST.txt"
test -f "$ALL_MOUNTS" && exit -1

cd "$(dirname "$0")" || exit -1
test -d "${TARGET_HOST}" || mkdir "${TARGET_HOST}"
cd "${TARGET_HOST}"

cat "$ALL_MOUNTS" | egrep "^\S+ on \S+ type btrfs" | cut -d' ' -f3 | while read MOUNTPOINT; do
  TMPFILE="$(mktemp wip.XXXXXXX)"
  ssh -n "${AGENT_USER}@${TARGET_HOST}" sudo btrfs show "$MOUNTPOINT" > $TMPFILE
  UUID="$(cat $TMPFILE | sed -e 's/\s\+/ /g' | sed -e 's/^\s*//g' | grep '^UUID:' | cut -d' ' -f2)"
  mv $TMPFILE $UUID
done

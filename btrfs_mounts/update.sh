#!/bin/bash
set -x

# check variables are set
test -z "$AGENT_USER" && exit -1
test -z "$TARGET_HOST" && exit -1


# run some other script before, to refresh input data
./all_mounts/update.sh || exit -1


#
# Prepare version control
#

git fetch origin master
git checkout master
git pull

#
#  Execute
#

ALL_MOUNTS="$PWD/all_mounts/$TARGET_HOST.txt"
test -f "$ALL_MOUNTS" ||  exit -1

cd "$(dirname "$0")" || exit -1
test -d "${TARGET_HOST}" || mkdir "${TARGET_HOST}"
cd "${TARGET_HOST}" || exit -1

rm *-*-*-*-*

cat "$ALL_MOUNTS" | egrep "^\S+ on \S+ type btrfs" | cut -d' ' -f3 | while read MOUNTPOINT; do
  TMPFILE="$(mktemp wip.XXXXXXX)"
  ssh -n "${AGENT_USER}@${TARGET_HOST}" sudo btrfs subvolume show "$MOUNTPOINT" > $TMPFILE
  UUID="$(cat $TMPFILE | sed -e 's/\s\+/ /g' | sed -e 's/^\s*//g' | grep '^UUID:' | cut -d' ' -f2)"
  echo $MOUNTPOINT > $UUID
  cat $TMPFILE| tail +2  >> $UUID
  rm $TMPFILE

  git add $UUID
done

#
#  Commit and Push
#

git commit -a -m "$(basename "$0"), $TARGET_HOST, $(date)"
git pull --rebase=true
git push

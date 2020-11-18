#!/bin/bash

# check variables are set
test -z "$AGENT_USER" && exit -1
test -z "$TARGET_HOST" && exit -1

cd "$(dirname "$0")"
test -f "$TARGET_HOST" && rm "$TARGET_HOST"
ssh -n "${AGENT_USER}@${TARGET_HOST}" mount > "$TARGET_HOST"

git add "$TARGET_HOST"
git commit -a -m "$(basename "$0"), $TARGET_HOST, $(date)"
git pull --rebase=true
git push

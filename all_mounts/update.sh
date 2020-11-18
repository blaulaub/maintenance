#!/bin/bash

# check variables are set
test -z "$AGENT_USER" && exit -1
test -z "$TARGET_HOST" && exit -1

RESULT_FILE="$TARGET_HOST.txt"

cd "$(dirname "$0")"
test -f "$RESULT_FILE" && rm "$RESULT_FILE"
ssh -n "${AGENT_USER}@${TARGET_HOST}" mount > "$RESULT_FILE"

git add "$RESULT_FILE"
git commit -a -m "$(basename "$0"), $TARGET_HOST, $(date)"
git pull --rebase=true
git push

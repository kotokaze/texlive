#!/usr/bin/env bash
set -e

SRC=${1}
DEST=${2}
OPTIONS=${3:-"--exclude-from=rsyncignore.txt"}

rsync -va --delete --delete-excluded ${OPTIONS} --stats ${SRC} ${DEST}

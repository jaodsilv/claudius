#!/bin/bash

input=$(cat)

tmpfile="/d/tmp/env_test/$RANDOM$RANDOM.txt"
echo "Random filename: $tmpfile"
echo "${CLAUDE_PLUGIN_ROOT}" > $tmpfile
echo "$@ / $0 / $1" >> $tmpfile
echo "${input}" >> $tmpfile

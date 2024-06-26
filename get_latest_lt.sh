#!/bin/bash

data=$(curl -s https://api.github.com/repos/languagetool-org/languagetool/tags)
regex='\"name\": \"([0-9v.]{1,6})\"'

if [[ $data =~ $regex ]]
then
  echo "LT_VERSION=${BASH_REMATCH[1]:1}" >> "$GITHUB_OUTPUT"
fi

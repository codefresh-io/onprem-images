#!/bin/bash

LISTS=$(ls -I "sha" -d releases/*)

for LIST in $LISTS
do
  cat $LIST | grep -i "^gcr.io/codefresh" >> gcr-images.txt
done

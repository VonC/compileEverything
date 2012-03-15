#!/bin/bash

NOREV=0000000000000000000000000000000000000000

while read oldsha newsha refname ; do
  # deleting is always safe
  if [[ $newsha == $NOREV ]]; then
    continue
  fi
  # make log argument be "..$newsha" when creating new branch
  if [[ $oldsha == $NOREV ]]; then
    revs=$newsha
  else
    revs=$oldsha..$newsha
  fi
  echo $revs

  glog=$(git log --format='%cn~%h~%s' $revs --not --all)
  for cns in $glog ; do
    atLeastOneCommit=true
    #echo "branch name: ${cns}"
    cn=`echo $cns | cut -d~ -f1`
    hash=`echo $cns | cut -d~ -f2`
    subject=`echo $cns | cut -d~ -f3`
    if [ "$cn" = "$GL_USER" ]; then
      echo "one commit found with $GL_USER as committer name"
      exit 0
    fi
  done
  echo "no commit found with $GL_USER as committer name"
  exit 1
done

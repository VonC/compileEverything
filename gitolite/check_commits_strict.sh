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

  IFS=$'\n' glog=$(git log --format='%an~%cn~%h~%s' $revs --not --all)
  for cns in $glog ; do
    atLeastOneCommit=true
    echo "branch name: ${cns}"
    an=`echo $cns | cut -d~ -f1`
    cn=`echo $cns | cut -d~ -f2`
    hash=`echo $cns | cut -d~ -f3`
    subject=`echo $cns | cut -d~ -f4`
    if [ "$an" != "$GL_USER" ]; then
      echo "Commit found with wrong author name for $hash ($subject)"
      echo "Should have been author '$GL_USER', was '$cn'"
      exit 1
    fi
    if [ "$cn" != "$GL_USER" ]; then
      echo "Commit found with wrong committer name for $hash ($subject)"
      echo "Should have been committer '$GL_USER', was '$cn'"
      exit 1
    fi
  done
  echo "All commits are from authoer and committer '$GL_USER' => pass"
  exit 0
done

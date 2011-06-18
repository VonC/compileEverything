#!/bin/bash
if [[ "$1" != "-force" ]]; then
  echo $0 not executed
  return 0
fi 
echo $0 executed

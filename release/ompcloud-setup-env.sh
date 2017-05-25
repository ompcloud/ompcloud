#!/bin/bash

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

# Directory of the script
BASEDIR=$(dirname "$0")
REAL_BASEDIR="$(realpath $BASEDIR)"

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  echo "ERROR this script should not to be sourced"
  echo "Run '$BASEDIR/ompcloud-setup-env.sh'"
  return
fi

mkdir -p $HOME/.ivy2/local/
rm -rf $HOME/.ivy2/local/org.llvm.openmp
cp -rf $REAL_BASEDIR/local/org.llvm.openmp $HOME/.ivy2/local/

echo "OmpCloud Spark library copied to SBT local repository"

#!/bin/bash

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

# Directory of the script
BASEDIR=$(dirname "$0")
REAL_BASEDIR="$(realpath $BASEDIR)"

echo "Copy OmpCloud Spark library to SBT local repository"
mkdir -p $HOME/.ivy2/local/
rm -rf $REAL_BASEDIR/local/org.llvm.openmp
cp -rf $REAL_BASEDIR/local/org.llvm.openmp $HOME/.ivy2/local/

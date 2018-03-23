#!/bin/bash
set -e

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

# Version of release
VERSION=$1

# Directory of the script
BASEDIR=$(dirname "$0")
REAL_BASEDIR="$(realpath $BASEDIR)"

OMPCLOUD_RI_PREFIX="/tmp/ompcloud-release"

OMPCLOUD_DIR=$(dirname "$REAL_BASEDIR")

RELEASE_NAME="ompcloud-$VERSION-linux-amd64"
RELEASE_DIR="$OMPCLOUD_RI_PREFIX/$RELEASE_NAME/"

mkdir -p $OMPCLOUD_RI_PREFIX

#OMPCloud
mkdir -p $RELEASE_DIR
mkdir -p $RELEASE_DIR/bin
mkdir -p $RELEASE_DIR/lib
mkdir -p $RELEASE_DIR/include
mkdir -p $RELEASE_DIR/test
mkdir -p $RELEASE_DIR/licences

cp -R $OMPCLOUD_DIR/conf $RELEASE_DIR
cp $OMPCLOUD_DIR/README.md $RELEASE_DIR
cp $OMPCLOUD_DIR/release/ompcloud-setup-env.sh $RELEASE_DIR
cp $OMPCLOUD_DIR/release/ompcloud-export-var.sh $RELEASE_DIR
cp $OMPCLOUD_DIR/release/mat-mul.c $RELEASE_DIR/test

# LLVM/Clang
cp -R $OMPCLOUD_RI_PREFIX/llvm-build/bin $RELEASE_DIR/
cd $OMPCLOUD_RI_PREFIX/llvm-build/lib/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/
cp $OMPCLOUD_RI_PREFIX/llvm-build/projects/openmp/runtime/src/omp.h $RELEASE_DIR/include/
cp -R $OMPCLOUD_RI_PREFIX/llvm-build/lib/clang $RELEASE_DIR/lib/
cp $OMPCLOUD_RI_PREFIX/llvm/LICENSE.TXT $RELEASE_DIR/licences/LICENSE-llvm.txt

# Libomptarget libraries
cd $OMPCLOUD_RI_PREFIX/libomptarget-build/lib/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/
cp $OMPCLOUD_RI_PREFIX/libomptarget/RTLs/cloud/inih/LICENSE.txt $RELEASE_DIR/licences/LICENSE-inih.txt

## Libhdfs3 libraries
cd $OMPCLOUD_RI_PREFIX/libhdfs3-build/src/
cp $OMPCLOUD_RI_PREFIX/libhdfs3/LICENSE $RELEASE_DIR/licences/LICENSE-libhdfs3.txt
cp $(ls | fgrep .so) $RELEASE_DIR/lib/

## Data of org.llvm.openmp for sbt
cp -R $HOME/.ivy2/local $RELEASE_DIR

cp $OMPCLOUD_DIR/install/ompcloud-install-dep.sh $RELEASE_DIR

## Create tarball
cd $OMPCLOUD_RI_PREFIX
tar -zcvf $OMPCLOUD_DIR/$RELEASE_NAME.tar.gz $RELEASE_NAME
rm -rf $RELEASE_DIR

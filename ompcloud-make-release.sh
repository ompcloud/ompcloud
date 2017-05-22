#!/bin/bash
set -e

# Version of release
VERSION=$1

OMPCLOUD_RI_PREFIX="/opt/release"
OMPCLOUD_DIR="/io"

RELEASE_NAME="ompcloud-$VERSION-linux-amd64"
RELEASE_DIR="$OMPCLOUD_RI_PREFIX/$RELEASE_NAME/"

mkdir -p $OMPCLOUD_RI_PREFIX

#OMPCloud
mkdir -p $RELEASE_DIR
mkdir -p $RELEASE_DIR/bin
mkdir -p $RELEASE_DIR/lib
mkdir -p $RELEASE_DIR/test

cp -R $OMPCLOUD_DIR/conf $RELEASE_DIR
cp $OMPCLOUD_DIR/LICENSE $RELEASE_DIR
cp $OMPCLOUD_DIR/README.md $RELEASE_DIR
cp $OMPCLOUD_DIR/release/ompcloud-setup-env.sh $RELEASE_DIR
cp $OMPCLOUD_DIR/release/ompcloud-export-var.sh $RELEASE_DIR
cp $OMPCLOUD_DIR/release/mat-mul.c $RELEASE_DIR/test

# LLVM/Clang
cp -R $OMPCLOUD_RI_PREFIX/llvm-build/bin $RELEASE_DIR/
cd $OMPCLOUD_RI_PREFIX/llvm-build/lib/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/
cp -R $OMPCLOUD_RI_PREFIX/llvm-build/lib/clang $RELEASE_DIR/lib/

# Libomptarget libraries
cd $OMPCLOUD_RI_PREFIX/libomptarget-build/lib/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/

## Libhdfs3 libraries
cd $OMPCLOUD_RI_PREFIX/libhdfs3-build/src/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/

## Data of org.llvm.openmp for sbt
cp -R $HOME/.ivy2/local $RELEASE_DIR

cp $OMPCLOUD_DIR/ompcloud-install-dep.sh $RELEASE_DIR

## Create tarball
cd $OMPCLOUD_RI_PREFIX
tar -zcvf /io/$RELEASE_NAME.tar.gz $RELEASE_NAME
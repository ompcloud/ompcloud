#!/bin/bash
# Install ompcloud tools in Ubuntu 16.04

# Any subsequent commands which fail will cause the script to exit immediately
set -e

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

BASEDIR=$(dirname "$0")

if [ $# -eq 0 ]
then
    echo "ERROR: No version especified"
    echo "Usage: $0 <release_version>"
    exit
fi

if [ ! -d "/io" ]; then
    echo "Entering ompcloud docker"

    sudo docker run -t -i --rm -v $(realpath $BASEDIR/..):/io ompcloud/ompcloud-test:latest /io/release/make-release.sh $1

    exit
fi

export OMPCLOUD_RELEASE_PREFIX="/opt/release"
export MAKE_ARGS="-j4"

export LIBHDFS3_SRC="$OMPCLOUD_RELEASE_PREFIX/libhdfs3"
export LIBHDFS3_BUILD="$OMPCLOUD_RELEASE_PREFIX/libhdfs3-build"

export OMPCLOUD_DIR="/io"
export OMPCLOUD_CONF_DIR="$OMPCLOUD_DIR/conf"
export OMPCLOUD_CONFHDFS_DIR="$OMPCLOUD_DIR/conf-hdfs"
export OMPCLOUD_SCRIPT_DIR="$OMPCLOUD_DIR/script"
export OMPCLOUD_CONF_PATH="$OMPCLOUD_CONF_DIR/cloud_rtl.ini.local"
export LIBHDFS3_CONF="$OMPCLOUD_CONF_DIR/hdfs-client.xml"

export LLVM_SRC="$OMPCLOUD_RELEASE_PREFIX/llvm"
export CLANG_SRC="$LLVM_SRC/tools/clang"
export LLVM_BUILD="$OMPCLOUD_RELEASE_PREFIX/llvm-build"
export LIBOMPTARGET_SRC="$OMPCLOUD_RELEASE_PREFIX/libomptarget"
export LIBOMPTARGET_BUILD="$OMPCLOUD_RELEASE_PREFIX/libomptarget-build"

export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin"
export LIBRARY_PATH="$LIBOMPTARGET_BUILD/lib:/usr/local/lib"
export LD_LIBRARY_PATH="$LIBOMPTARGET_BUILD/lib:/usr/local/lib"

export INSTALL_RELEASE_SCRIPT="$OMPCLOUD_DIR/release/ompcloud-install-release-ubuntu.sh"

export RELEASE_DIR="$OMPCLOUD_RELEASE_PREFIX/ompcloud-$1-linux-amd64"
export INCLUDE_DIR="$RELEASE_DIR/lib/clang/3.8.0"

mkdir -p $OMPCLOUD_RELEASE_PREFIX

# Install libhdfs3
mkdir $LIBHDFS3_SRC
git clone git://github.com/Pivotal-Data-Attic/pivotalrd-libhdfs3.git $LIBHDFS3_SRC
mkdir $LIBHDFS3_BUILD
cd $LIBHDFS3_BUILD
cmake $LIBHDFS3_SRC
make $MAKE_ARGS
make install

# Build libomptarget
git clone --recursive git://github.com/ompcloud/libomptarget.git $LIBOMPTARGET_SRC
mkdir $LIBOMPTARGET_BUILD
cd $LIBOMPTARGET_BUILD
cmake -DCMAKE_BUILD_TYPE=Debug $LIBOMPTARGET_SRC
make $MAKE_ARGS

# Build llvm/clang
git clone git://github.com/ompcloud/llvm.git $LLVM_SRC
git clone git://github.com/ompcloud/clang.git $CLANG_SRC
mkdir $LLVM_BUILD
cd $LLVM_BUILD
cmake $LLVM_SRC -DLLVM_TARGETS_TO_BUILD="X86" -DCMAKE_BUILD_TYPE=Release
make $MAKE_ARGS

#OMPCloud
mkdir -p $RELEASE_DIR
cp -R $OMPCLOUD_CONF_DIR $RELEASE_DIR
cp -R $OMPCLOUD_CONFHDFS_DIR $RELEASE_DIR
cp -R $OMPCLOUD_SCRIPT_DIR $RELEASE_DIR

mkdir -p $RELEASE_DIR/bin
mkdir -p $INCLUDE_DIR

# LLVM/Clang Binaries
cd $LLVM_BUILD/bin/
cp * $RELEASE_DIR/bin/

# LLVM/CLang libraries
cd $LLVM_BUILD/lib/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/
cp -R clang/3.8.0/include $INCLUDE_DIR

# Libomptarget libraries
cd $LIBOMPTARGET_BUILD/lib/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/

## Libhdfs3 libraries
cd $LIBHDFS3_BUILD/src/
cp $(ls | fgrep .so) $RELEASE_DIR/lib/
## mkdir $RELEASE_DIR/src
##cp $LIBHDFS3_BUILD/src/*.so.* $RELEASE_DIR/src

cd $OMPCLOUD_RELEASE_PREFIX

## Data of org.llvm.openmp for sbt
cp -R $HOME/.ivy2/local $RELEASE_DIR

cp $INSTALL_RELEASE_SCRIPT $RELEASE_DIR

cd $RELEASE_DIR
## Create tarball
tar -zcvf $RELEASE_DIR.tar.gz *

## Get tarball from docker
mv $RELEASE_DIR.tar.gz /io/

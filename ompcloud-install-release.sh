#!/bin/bash

set -e

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

function print_usage {
    echo "Usage: $0 <-r || -i> [<version>]"
    echo "      -r <version>: Generate release tarball of ompcloud"
    echo "      -i [<install-dir>]: Install OmpCloud in current system"
    echo "      -ri [<install-dir>]: Install OmpCloud from release"
    echo "      -h: Print this help"
}

if [ $# -eq 0 ]; then
    echo "ERROR: No operation mode especified"
    print_usage
    exit
elif [ $# -eq 1 ]; then
    if [ $1 == "-h" ]; then
        print_usage
        exit
    elif [ $1 == "-r" ]; then
        echo "ERROR: Need to specify the release version number"
        print_usage
        exit
    elif [ $1 != "-i" ] || [ $1 != "-ri" ]; then
        echo "ERROR: Unknown operation mode"
        print_usage
        exit
    else
      echo "ERROR: Need to specify the installation directory"
      print_usage
      exit
    fi
fi

# Directory of the script
BASEDIR=$(dirname "$0")
REAL_BASEDIR="$(realpath $BASEDIR)"
# Operation mode
OP=$1

SUDO=''
if (( $EUID != 0 )); then
  SUDO='sudo'
fi

if [ $OP == "-r" ]; then
    # Version of release
    VERSION=$2

    export OMPCLOUD_RI_PREFIX="/opt/release"
    export LIBHDFS3_INCLUDE_LINK="/usr/local/include/hdfs"

    export OMPCLOUD_DIR="/io"
    export OMPCLOUD_CONF_DIR="$OMPCLOUD_DIR/conf"
    export OMPCLOUD_CONFHDFS_DIR="$OMPCLOUD_DIR/conf-hdfs"
    export OMPCLOUD_SCRIPT_DIR="$OMPCLOUD_DIR/script"

    export INSTALL_RELEASE_SCRIPT="$OMPCLOUD_DIR/ompcloud-install-release.sh"

    export RELEASE_DIR="$OMPCLOUD_RI_PREFIX/ompcloud-$VERSION-linux-amd64"
    export OMPCLOUD_CONF_DIR_R="$RELEASE_DIR/ompcloud-conf"
    export OMPCLOUD_CONFHDFS_DIR_R="$RELEASE_DIR/conf-hdfs"
    export OMPCLOUD_SCRIPT_DIR_R="$RELEASE_DIR/ompcloud-script"
    export INCLUDE_DIR="$RELEASE_DIR/lib/clang/3.8.0"
else
    export OMPCLOUD_RI_PREFIX="$2"

    if [ $# -eq 3 ] && [ $3 == "-d" ]; then
        DOCKER=1
    else
        DOCKER=0
    fi

    export OMPCLOUD_CONF_DIR="$OMPCLOUD_RI_PREFIX/ompcloud-conf"
    export OMPCLOUD_SCRIPT_DIR="$OMPCLOUD_RI_PREFIX/ompcloud-script"

    export HADOOP_REPO="http://www-eu.apache.org"
    export HADOOP_VERSION="2.7.3"
    export HADOOP_HOME="$OMPCLOUD_RI_PREFIX/hadoop-$HADOOP_VERSION"
    export HADOOP_CONF="$HADOOP_HOME/etc/hadoop"

    export SPARK_REPO="http://d3kbcqa49mib13.cloudfront.net"
    export SPARK_VERSION="2.1.0"
    export SPARK_HADOOP_VERSION="2.7"
    export SPARK_HOME="$OMPCLOUD_RI_PREFIX/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION"

    export OPENMP_SRC="$OMPCLOUD_RI_PREFIX/openmp"
    export OPENMP_BUILD="$OMPCLOUD_RI_PREFIX/openmp-build"
    export UNIBENCH_SRC="$OMPCLOUD_RI_PREFIX/Unibench"
    export UNIBENCH_BUILD="$OMPCLOUD_RI_PREFIX/Unibench-build"

    export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$PATH"
    export LIBRARY_PATH="$LIBOMPTARGET_BUILD/lib:$LIBRARY_PATH"
    export LD_LIBRARY_PATH="$LIBOMPTARGET_BUILD/lib:$LD_LIBRARY_PATH"
fi

export MAKE_ARGS="-j4"

if [ $OP == "-ri" ]; then
    export LIBHDFS3_BUILD="$REAL_BASEDIR"

    export OMPCLOUD_CONF_PATH="$OMPCLOUD_CONF_DIR/cloud_rtl.ini.local"
    export LIBHDFS3_CONF="$OMPCLOUD_CONF_DIR/hdfs-client.xml"

    export LLVM_BUILD="$REAL_BASEDIR"
    export LIBOMPTARGET_BUILD="$REAL_BASEDIR"
else
    export LIBHDFS3_SRC="$OMPCLOUD_RI_PREFIX/libhdfs3"
    export LIBHDFS3_BUILD="$OMPCLOUD_RI_PREFIX/libhdfs3-build"

    export OMPCLOUD_CONF_PATH="$OMPCLOUD_CONF_DIR/cloud_rtl.ini.local"
    export LIBHDFS3_CONF="$OMPCLOUD_CONF_DIR/hdfs-client.xml"

    export LLVM_SRC="$OMPCLOUD_RI_PREFIX/llvm"
    export CLANG_SRC="$LLVM_SRC/tools/clang"
    export LLVM_BUILD="$OMPCLOUD_RI_PREFIX/llvm-build"
    export LIBOMPTARGET_SRC="$OMPCLOUD_RI_PREFIX/libomptarget"
    export LIBOMPTARGET_BUILD="$OMPCLOUD_RI_PREFIX/libomptarget-build"
fi

export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"

if [ $OP == "-ri" ]; then
    cp -R $REAL_BASEDIR/local $HOME/.ivy2/
fi

mkdir -p $OMPCLOUD_RI_PREFIX

if [ $OP == "-i" ] || [ $OP == "-r" ]; then

    # Install libhdfs3
    mkdir $LIBHDFS3_SRC
    git clone git://github.com/Pivotal-Data-Attic/pivotalrd-libhdfs3.git $LIBHDFS3_SRC
    mkdir $LIBHDFS3_BUILD
    cd $LIBHDFS3_BUILD
    cmake $LIBHDFS3_SRC
    make $MAKE_ARGS

    if [ $OP == "-i" ]; then
        $SUDO make install
    fi

    if [ $OP == "-r" ]; then
        ln -s $LIBHDFS3_SRC/src/client $LIBHDFS3_INCLUDE_LINK
    fi

    # Build libomptarget
    git clone git://github.com/ompcloud/libomptarget.git $LIBOMPTARGET_SRC
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
fi

if [ $OP == "-r" ]; then
    #OMPCloud
    mkdir -p $RELEASE_DIR
    mkdir -p $OMPCLOUD_CONF_DIR_R
    mkdir -p $OMPCLOUD_CONFHDFS_DIR_R
    mkdir -p $OMPCLOUD_SCRIPT_DIR_R

    cp -R $OMPCLOUD_CONF_DIR/* $OMPCLOUD_CONF_DIR_R
    cp -R $OMPCLOUD_CONFHDFS_DIR/* $OMPCLOUD_CONFHDFS_DIR_R
    cp -R $OMPCLOUD_SCRIPT_DIR/* $OMPCLOUD_SCRIPT_DIR_R

    cp $OMPCLOUD_DIR/LICENSE $RELEASE_DIR
    cp $OMPCLOUD_DIR/README.md $RELEASE_DIR
    cp $OMPCLOUD_DIR/release/INSTALL $RELEASE_DIR
    cp $OMPCLOUD_DIR/release/Makefile $RELEASE_DIR

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

    cd $OMPCLOUD_RI_PREFIX

    ## Data of org.llvm.openmp for sbt
    cp -R $HOME/.ivy2/local $RELEASE_DIR

    cp $INSTALL_RELEASE_SCRIPT $RELEASE_DIR

    cd $RELEASE_DIR
    ## Create tarball
    tar -zcvf $RELEASE_DIR.tar.gz *

    ## Get tarball from docker
    mv $RELEASE_DIR.tar.gz /io/
else
    # Install hadoop and spark
    wget -nv -P $OMPCLOUD_RI_PREFIX $SPARK_REPO/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION.tgz
    wget -nv -P $OMPCLOUD_RI_PREFIX $HADOOP_REPO/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
    cd $OMPCLOUD_RI_PREFIX
    tar -zxf $OMPCLOUD_RI_PREFIX/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION.tgz
    tar -zxf $OMPCLOUD_RI_PREFIX/hadoop-$HADOOP_VERSION.tar.gz

    if [ $DOCKER -eq 0 ]; then
        cp $REAL_BASEDIR/conf-hdfs/core-site.xml $HADOOP_CONF
        cp $REAL_BASEDIR/conf-hdfs/hdfs-site.xml $HADOOP_CONF
        cp $REAL_BASEDIR/conf-hdfs/config $HOME/.ssh
    fi

    # Configure Hadoop and Spark
    # FIXME: JAVA_HOME is hard coded
    sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/\n:' $HADOOP_CONF/hadoop-env.sh

    # Create aliases for managining the HDFS server
    $SUDO bash -c "printf '#!/bin/bash\nstart-dfs.sh;start-yarn.sh' > /usr/bin/hdfs-start"
    $SUDO bash -c "printf '#!/bin/bash\nstop-yarn.sh;stop-dfs.sh' > /usr/bin/hdfs-stop"
    $SUDO bash -c "printf '#!/bin/bash\nhdfs-stop;rm -rf $OMPCLOUD_RI_PREFIX/hadoop/hdfs/datanode;hdfs namenode -format -force;hdfs-start' > /usr/bin/hdfs-reset"
    $SUDO chmod ugo+x /usr/bin/hdfs-start /usr/bin/hdfs-stop /usr/bin/hdfs-reset

    # Prebuild Unibench
    git clone git://github.com/ompcloud/UniBench.git $UNIBENCH_SRC
fi

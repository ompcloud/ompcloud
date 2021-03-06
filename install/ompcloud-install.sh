#!/bin/bash
set -e

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

function print_usage {
    echo "Usage: $0 <-r || -i> [<install-dir>]"
    echo "      -r : Install OmpCloud for releasing"
    echo "      -i [<install-dir>]: Install OmpCloud in current system"
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
    elif [ $1 == "-i" ]; then
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
    OMPCLOUD_RI_PREFIX="/tmp/ompcloud-release"
else
    OMPCLOUD_RI_PREFIX="$2"

    if [ $# -eq 3 ] && [ $3 == "-d" ]; then
        DOCKER=1
    else
        DOCKER=0
    fi
fi

APACHE_MIRROR="http://apache.mirrors.tds.net"

HADOOP_VERSION="2.7.7"
HADOOP_HOME="$OMPCLOUD_RI_PREFIX/hadoop-$HADOOP_VERSION"
HADOOP_CONF="$HADOOP_HOME/etc/hadoop"

SPARK_VERSION="2.2.2"
SPARK_HADOOP_VERSION="2.7"
SPARK_HOME="$OMPCLOUD_RI_PREFIX/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION"

OPENMP_SRC="$OMPCLOUD_RI_PREFIX/openmp"
OPENMP_BUILD="$OMPCLOUD_RI_PREFIX/openmp-build"
UNIBENCH_SRC="$OMPCLOUD_RI_PREFIX/Unibench"
UNIBENCH_BUILD="$OMPCLOUD_RI_PREFIX/Unibench-build"

LIBHDFS3_SRC="$OMPCLOUD_RI_PREFIX/libhdfs3"
LIBHDFS3_BUILD="$OMPCLOUD_RI_PREFIX/libhdfs3-build"
LLVM_SRC="$OMPCLOUD_RI_PREFIX/llvm"
LLVM_BUILD="$OMPCLOUD_RI_PREFIX/llvm-build"
LIBOMPTARGET_SRC="$OMPCLOUD_RI_PREFIX/libomptarget"
LIBOMPTARGET_BUILD="$OMPCLOUD_RI_PREFIX/libomptarget-build"

if [ $OP = "-r" ]; then
    export LDFLAGS="$LDFLAGS -static-libstdc++"
fi

# Install building tools
if [ -n "$(command -v apt-get)" ]
then
  $SUDO apt-get install -y build-essential cmake git wget
elif [ -n "$(command -v yum)" ]
then
  $SUDO yum -y install gcc gcc-c++ make cmake git wget
else
  echo "WARNING: your package manager is not yet supported by this script."
fi

mkdir -p $OMPCLOUD_RI_PREFIX

# Install protobuf (static compilation)
cd $OMPCLOUD_RI_PREFIX
wget https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
tar --no-same-owner -xzf protobuf-2.6.1.tar.gz
cd protobuf-2.6.1
./configure --disable-shared "CFLAGS=-fPIC" "CXXFLAGS=-fPIC"
make $MAKE_ARGS
$SUDO make install

# Install libhdfs3
mkdir $LIBHDFS3_SRC
git clone git://github.com/ompcloud/libhdfs3.git $LIBHDFS3_SRC
mkdir $LIBHDFS3_BUILD
cd $LIBHDFS3_BUILD
cmake $LIBHDFS3_SRC -DCMAKE_BUILD_TYPE=Release
make $MAKE_ARGS
$SUDO make install

# Build libomptarget
git clone git://github.com/ompcloud/libomptarget.git $LIBOMPTARGET_SRC
mkdir $LIBOMPTARGET_BUILD
cd $LIBOMPTARGET_BUILD
cmake -DCMAKE_BUILD_TYPE=Debug $LIBOMPTARGET_SRC
make $MAKE_ARGS

# Build llvm/clang
git clone git://github.com/ompcloud/llvm.git $LLVM_SRC
git clone git://github.com/ompcloud/clang.git $LLVM_SRC/tools/clang
git clone -b release_38 git://github.com/llvm-mirror/openmp.git $LLVM_SRC/projects/openmp
mkdir $LLVM_BUILD
cd $LLVM_BUILD
cmake $LLVM_SRC -DLLVM_TARGETS_TO_BUILD="X86" -DCMAKE_BUILD_TYPE=Release -DCLANG_VENDOR="OmpCloud" -DLLVM_BUILD_TOOLS=OFF
make $MAKE_ARGS

if [ $OP != "-r" ]; then
    # Install hadoop and spark
    wget -nv -P $OMPCLOUD_RI_PREFIX $APACHE_MIRROR/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION.tgz
    wget -nv -P $OMPCLOUD_RI_PREFIX $APACHE_MIRROR/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
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

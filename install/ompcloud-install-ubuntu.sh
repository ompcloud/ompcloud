#!/bin/bash
# Install ompcloud tools in Ubuntu 16.04

# Any subsequent commands which fail will cause the script to exit immediately
set -e

BASEDIR=$(dirname "$0")

export OMPCLOUD_INSTALL_PREFIX="/home/ubuntu/workspace"
export MAKE_ARGS="-j4"

export CGCLOUD_HOME="$OMPCLOUD_INSTALL_PREFIX/cgcloud"
export LIBHDFS3_SRC="$OMPCLOUD_INSTALL_PREFIX/libhdfs3"
export LIBHDFS3_BUILD="$OMPCLOUD_INSTALL_PREFIX/libhdfs3-build"

export OMPCLOUD_CONF_DIR="$OMPCLOUD_INSTALL_PREFIX/ompcloud/conf"
export OMPCLOUD_SCRIPT_DIR="$OMPCLOUD_INSTALL_PREFIX/ompcloud/scripts"
export OMPCLOUD_CONF_PATH="$OMPCLOUD_CONF_DIR/cloud_rtl.ini.local"
export LIBHDFS3_CONF="$OMPCLOUD_CONF_DIR/hdfs-client.xml"

export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"

export HADOOP_REPO="http://www-eu.apache.org"
export HADOOP_VERSION="2.7.3"
export HADOOP_HOME="$OMPCLOUD_INSTALL_PREFIX/hadoop-$HADOOP_VERSION"
export HADOOP_CONF="$HADOOP_HOME/etc/hadoop"

export SPARK_REPO="http://d3kbcqa49mib13.cloudfront.net"
export SPARK_VERSION="2.1.0"
export SPARK_HADOOP_VERSION="2.7"
export SPARK_HOME="$OMPCLOUD_INSTALL_PREFIX/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION"

export LLVM_SRC="$OMPCLOUD_INSTALL_PREFIX/llvm"
export CLANG_SRC="$LLVM_SRC/tools/clang"
export LLVM_BUILD="$OMPCLOUD_INSTALL_PREFIX/llvm-build"
export LIBOMPTARGET_SRC="$OMPCLOUD_INSTALL_PREFIX/libomptarget"
export LIBOMPTARGET_BUILD="$OMPCLOUD_INSTALL_PREFIX/libomptarget-build"
export OPENMP_SRC="$OMPCLOUD_INSTALL_PREFIX/openmp"
export OPENMP_BUILD="$OMPCLOUD_INSTALL_PREFIX/openmp-build"
export UNIBENCH_SRC="$OMPCLOUD_INSTALL_PREFIX/Unibench"
export UNIBENCH_BUILD="$OMPCLOUD_INSTALL_PREFIX/Unibench-build"
export OMPCLOUDTEST_SRC="$OMPCLOUD_INSTALL_PREFIX/ompcloud-test"
export OMPCLOUDTEST_BUILD="$OMPCLOUD_INSTALL_PREFIX/ompcloud-test-build"

export CGCLOUD_PLUGINS="cgcloud.spark"

export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin"
export LIBRARY_PATH="$LIBOMPTARGET_BUILD/lib:/usr/local/lib"
export LD_LIBRARY_PATH="$LIBOMPTARGET_BUILD/lib:/usr/local/lib"

if env | grep -q ^LC_ALL=
then
  echo "LC_ALL is already exported"
else
  echo "LC_ALL has been set to avoid problem"
  export LC_ALL="en_US.UTF-8"
fi

# Install needed package
sudo apt-get update && \
  sudo apt-get install -y apt-utils apt-transport-https

sbt_list="/etc/apt/sources.list.d/sbt.list"
if [ -f "$sbt_list" ]
then
	echo "Sbt repository is already in apt sources list."
else
  echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a $sbt_list
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
fi

sudo apt-get clean all && \
  sudo apt-get update && \
  sudo apt-get upgrade -y

# Default Java 9 does not seem to be compatible with SBT
sudo apt-get install -y openjdk-8-jre-headless cmake wget libxml2-dev uuid-dev \
  libprotobuf-dev protobuf-compiler libgsasl7-dev libkrb5-dev \
  libboost-all-dev libssh-dev libelf-dev libffi-dev python-pip sbt \
  openssh-server git

sudo pip install s3cmd virtualenv virtualenvwrapper

mkdir -p $OMPCLOUD_INSTALL_PREFIX

# Install libhdfs3
mkdir $LIBHDFS3_SRC
git clone git://github.com/Pivotal-Data-Attic/pivotalrd-libhdfs3.git $LIBHDFS3_SRC
mkdir $LIBHDFS3_BUILD
cd $LIBHDFS3_BUILD
cmake $LIBHDFS3_SRC
make $MAKE_ARGS
sudo make install

# Install openmp
git clone git://github.com/llvm-mirror/openmp.git $OPENMP_SRC
mkdir $OPENMP_BUILD
cd $OPENMP_BUILD
cmake -DCMAKE_BUILD_TYPE=Release $OPENMP_SRC
make $MAKE_ARGS
sudo make install

# Install hadoop and spark
wget -nv -P $OMPCLOUD_INSTALL_PREFIX $SPARK_REPO/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION.tgz
wget -nv -P $OMPCLOUD_INSTALL_PREFIX $HADOOP_REPO/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
cd $OMPCLOUD_INSTALL_PREFIX
tar -zxf $OMPCLOUD_INSTALL_PREFIX/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION.tgz
tar -zxf $OMPCLOUD_INSTALL_PREFIX/hadoop-$HADOOP_VERSION.tar.gz

cp $BASEDIR/../conf-hdfs/core-site.xml $HADOOP_CONF
cp $BASEDIR/../conf-hdfs/hdfs-site.xml $HADOOP_CONF
#cp ../conf-hdfs/config ~/.ssh

# Configure SSH
#ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa
#cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

# Install cgcloud
git clone -b spark-2.0 git://github.com/hyviquel/cgcloud.git $CGCLOUD_HOME
/bin/bash -c "source /usr/local/bin/virtualenvwrapper.sh \
    && cd $CGCLOUD_HOME \
    && mkvirtualenv cgcloud \
    && workon cgcloud \
    && make develop sdist"

# TOFIX Create alias for running cgcloud easily
#echo '#!/bin/bash\n$WORKON_HOME/cgcloud/bin/cgcloud $@' | sudo tee -a /usr/bin/cgcloud
#sudo chmod ugo+x /usr/bin/cgcloud

# Configure Hadoop and Spark
# FIXME: JAVA_HOME is hard coded
sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/\n:' $HADOOP_CONF/hadoop-env.sh

# TOFIX Create aliases for managining the HDFS server
#sudo bash -c "echo '#!/bin/bash\nstart-dfs.sh;start-yarn.sh' > /usr/bin/hdfs-start"
#sudo bash -c "echo '#!/bin/bash\nstop-yarn.sh;stop-dfs.sh' > /usr/bin/hdfs-stop"
#sudo bash -c "echo '#!/bin/bash\nhdfs-stop;rm -rf $OMPCLOUD_INSTALL_PREFIX/hadoop/hdfs/datanode;hdfs namenode -format -force;hdfs-start' > /usr/bin/hdfs-reset"
#sudo chmod ugo+x /usr/bin/hdfs-start /usr/bin/hdfs-stop /usr/bin/hdfs-reset

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

# Prebuild Unibench
git clone git://github.com/ompcloud/UniBench.git $UNIBENCH_SRC
mkdir $UNIBENCH_BUILD
cd $UNIBENCH_BUILD
export CC=$LLVM_BUILD/bin/clang
cmake $UNIBENCH_SRC -DCMAKE_BUILD_TYPE=Release  -DRUN_TEST=OFF -DRUN_BENCHMARK=ON -DCMAKE_BUILD_TYPE=Release
make experiments

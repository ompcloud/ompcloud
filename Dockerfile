
FROM phusion/baseimage:0.9.21
MAINTAINER Hervé Yviquel <hyviquel@gmail.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN rm -f /etc/service/sshd/down

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

ENV INSTALL_DIR /opt
ENV OMPCLOUD_DIR $INSTALL_DIR/ompcloud

# Configuration options.
ENV CGCLOUD_HOME $INSTALL_DIR/cgcloud
ENV LIBHDFS3_SRC $INSTALL_DIR/libhdfs3
ENV LIBHDFS3_BUILD $INSTALL_DIR/libhdfs3-build
ENV OMPCLOUD_CONF_DIR $OMPCLOUD_DIR/conf
ENV OMPCLOUD_SCRIPT_DIR $OMPCLOUD_DIR/script
ENV CLOUD_TEMP /tmp/cloud
ENV OMPCLOUD_CONF_PATH $OMPCLOUD_CONF_DIR/cloud_rtl.ini.local
ENV LIBHDFS3_CONF $OMPCLOUD_CONF_DIR/hdfs-client.xml

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

ENV HADOOP_REPO http://www-eu.apache.org
ENV HADOOP_VERSION 2.7.3
ENV HADOOP_HOME $INSTALL_DIR/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF $HADOOP_HOME/etc/hadoop

ENV SPARK_REPO http://d3kbcqa49mib13.cloudfront.net
ENV SPARK_VERSION 2.1.0
ENV SPARK_HADOOP_VERSION 2.7
ENV SPARK_HOME $INSTALL_DIR/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION

ENV LLVM_SRC $INSTALL_DIR/llvm
ENV CLANG_SRC $LLVM_SRC/tools/clang
ENV LLVM_BUILD $INSTALL_DIR/llvm-build
ENV LIBOMPTARGET_SRC $INSTALL_DIR/libomptarget
ENV LIBOMPTARGET_BUILD $INSTALL_DIR/libomptarget-build
ENV OPENMP_SRC $INSTALL_DIR/openmp
ENV OPENMP_BUILD $INSTALL_DIR/openmp-build
ENV UNIBENCH_SRC $INSTALL_DIR/Unibench
ENV UNIBENCH_BUILD $INSTALL_DIR/Unibench-build
ENV OMPCLOUDTEST_SRC $INSTALL_DIR/ompcloud-test
ENV OMPCLOUDTEST_BUILD $INSTALL_DIR/ompcloud-test-build

ENV PATH $HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$PATH
ENV LIBRARY_PATH $LIBOMPTARGET_BUILD/lib:$LIBRARY_PATH
ENV LD_LIBRARY_PATH $LIBOMPTARGET_BUILD/lib:$LD_LIBRARY_PATH

COPY . $OMPCLOUD_DIR
RUN chmod +x $OMPCLOUD_DIR/ompcloud-install-dep.sh $OMPCLOUD_DIR/ompcloud-install-release.sh
RUN $OMPCLOUD_DIR/ompcloud-install-dep.sh
RUN $OMPCLOUD_DIR/ompcloud-install-release.sh -i $INSTALL_DIR -d

COPY conf-hdfs/core-site.xml $HADOOP_CONF
COPY conf-hdfs/hdfs-site.xml $HADOOP_CONF
COPY conf-hdfs/config /root/.ssh
RUN chmod +x $OMPCLOUD_SCRIPT_DIR/*

ENV TERM xterm

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

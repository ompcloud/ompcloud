
FROM phusion/baseimage:0.9.19
MAINTAINER Hervé Yviquel <hyviquel@gmail.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN rm -f /etc/service/sshd/down

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

ENV OMPCLOUD_INSTALL_DIR /opt
ENV OMPCLOUD_DIR $OMPCLOUD_INSTALL_DIR/ompcloud

# Configuration options.
ENV OMPCLOUD_CONF_PATH $OMPCLOUD_DIR/conf/cloud_local.ini
ENV LIBHDFS3_CONF $OMPCLOUD_DIR/conf/hdfs-client.xml

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

ENV HADOOP_VERSION 2.7.5
ENV HADOOP_HOME $OMPCLOUD_INSTALL_DIR/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF $HADOOP_HOME/etc/hadoop

ENV SPARK_VERSION 2.2.1
ENV SPARK_HADOOP_VERSION 2.7
ENV SPARK_HOME $OMPCLOUD_INSTALL_DIR/spark-$SPARK_VERSION-bin-hadoop$SPARK_HADOOP_VERSION

ENV PATH $HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$OMPCLOUD_INSTALL_DIR/llvm-build/bin:$PATH
ENV LIBRARY_PATH $OMPCLOUD_INSTALL_DIR/libomptarget-build/lib:$OMPCLOUD_INSTALL_DIR/llvm-build/lib:$LIBRARY_PATH
ENV LD_LIBRARY_PATH $OMPCLOUD_INSTALL_DIR/libomptarget-build/lib:$OMPCLOUD_INSTALL_DIR/llvm-build/lib:$LD_LIBRARY_PATH
ENV CPATH $OMPCLOUD_INSTALL_DIR/llvm-build/projects/openmp/runtime/src:$CPATH

COPY . $OMPCLOUD_DIR
RUN chmod +x $OMPCLOUD_DIR/install/ompcloud-install-dep.sh $OMPCLOUD_DIR/install/ompcloud-install.sh
RUN $OMPCLOUD_DIR/install/ompcloud-install-dep.sh
RUN apt-get install -y openssh-server

RUN $OMPCLOUD_DIR/install/ompcloud-install.sh -i $OMPCLOUD_INSTALL_DIR -d

COPY conf-hdfs/core-site.xml $HADOOP_CONF
COPY conf-hdfs/hdfs-site.xml $HADOOP_CONF
COPY conf-hdfs/config /root/.ssh
RUN chmod +x $OMPCLOUD_DIR/script/*

# Configure SSH
RUN ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa
RUN cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
RUN service ssh start

ENV TERM xterm

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

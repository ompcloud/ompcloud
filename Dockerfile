
FROM phusion/baseimage:0.9.19
MAINTAINER Hervé Yviquel <hyviquel@gmail.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN rm -f /etc/service/sshd/down

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Configuration options.
ENV CGCLOUD_HOME /opt/cgcloud
ENV LIBHDFS3_SRC /opt/libhdfs3
ENV LIBHDFS3_BUILD /opt/libhdfs3-build
ENV CLOUD_CONF_DIR /opt/cloud-conf

ENV HADOOP_REPO http://www-eu.apache.org
ENV SPARK_REPO http://d3kbcqa49mib13.cloudfront.net

ENV LLVM_SRC /opt/llvm
ENV CLANG_SRC $LLVM_SRC/tools/clang
ENV LLVM_BUILD /opt/llvm-build
ENV LIBOMPTARGET_SRC /opt/libomptarget
ENV LIBOMPTARGET_BUILD /opt/libomptarget-build
ENV OPENMP_SRC /opt/openmp
ENV OPENMP_BUILD /opt/openmp-build
ENV UNIBENCH_SRC /opt/Unibench
ENV UNIBENCH_BUILD /opt/Unibench-build

ENV PATH $PATH
ENV LIBRARY_PATH $LIBOMPTARGET_BUILD/lib:/usr/local/lib
ENV LD_LIBRARY_PATH $LIBOMPTARGET_BUILD/lib:/usr/local/lib

# Install needed package
RUN apt-get update && \
    apt-get install -y apt-utils apt-transport-https
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
RUN apt-get update && \
    apt-get upgrade -y
# Default Java 9 does not seem to be compatible with SBT
RUN apt-get install -y openjdk-8-jre-headless cmake wget libxml2-dev uuid-dev \
    libprotobuf-dev protobuf-compiler libgsasl7-dev libkrb5-dev \
    libboost-all-dev libssh-dev libelf-dev libffi-dev python-pip sbt \
    openssh-server git
RUN pip install --upgrade pip s3cmd

# Install libhdfs3
RUN git clone --depth 1 git://github.com/Pivotal-Data-Attic/pivotalrd-libhdfs3.git $LIBHDFS3_SRC
RUN mkdir $LIBHDFS3_BUILD; cd $LIBHDFS3_BUILD; cmake $LIBHDFS3_SRC; make -j2; make install; make clean

# Install openmp
RUN git clone --depth 1 git://github.com/llvm-mirror/openmp.git $OPENMP_SRC
RUN mkdir $OPENMP_BUILD; cd $OPENMP_BUILD; cmake -DCMAKE_BUILD_TYPE=Release $OPENMP_SRC; make -j2 install; make clean

# Install hadoop and spark
RUN wget -nv -P /opt/ $SPARK_REPO/spark-2.0.1-bin-hadoop2.7.tgz
RUN wget -nv -P /opt/ $HADOOP_REPO/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
RUN cd /opt/; tar -zxf /opt/spark-2.0.1-bin-hadoop2.7.tgz; tar -zxf /opt/hadoop-2.7.3.tar.gz
RUN rm /opt/spark-2.0.1-bin-hadoop2.7.tgz /opt/hadoop-2.7.3.tar.gz

# Configure SSH
RUN ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa
RUN cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
RUN service ssh start

# Install virtualenv
RUN pip install virtualenv virtualenvwrapper
RUN mkdir -p /opt/virtualenvs
ENV WORKON_HOME /opt/virtualenvs
RUN git clone -b spark-2.0 --depth 1 git://github.com/hyviquel/cgcloud.git $CGCLOUD_HOME

# Install cgcloud
RUN /bin/bash -c "source /usr/local/bin/virtualenvwrapper.sh \
    && cd $CGCLOUD_HOME \
    && mkvirtualenv cgcloud \
    && workon cgcloud \
    && make develop sdist"

# Preconfigure cgcloud
ENV CGCLOUD_PLUGINS cgcloud.spark
ENV CGCLOUD_ME ompcloud-user

# Create alias for running cgcloud easily
RUN echo '#!/bin/bash\n$WORKON_HOME/cgcloud/bin/cgcloud $@' > /usr/bin/cgcloud; \
    chmod +x /usr/bin/cgcloud

# Configure Hadoop and Spark
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV HADOOP_HOME /opt/hadoop-2.7.3
ENV HADOOP_CONF $HADOOP_HOME/etc/hadoop/
ENV SPARK_HOME /opt/spark-2.0.1-bin-hadoop2.7/
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\n:' $HADOOP_CONF/hadoop-env.sh

# Create aliases for managining the HDFS server
RUN echo '#!/bin/bash\nstart-dfs.sh;start-yarn.sh' > /usr/bin/hdfs-start; \
    echo '#!/bin/bash\nstop-yarn.sh;stop-dfs.sh' > /usr/bin/hdfs-stop; \
    echo '#!/bin/bash\nhdfs-stop;rm -rf /opt/hadoop/hdfs/datanode;hdfs namenode -format;hdfs-start' > /usr/bin/hdfs-reset; \
    chmod +x /usr/bin/hdfs-start /usr/bin/hdfs-stop /usr/bin/hdfs-reset

RUN mkdir $CLOUD_CONF_DIR
ADD config-rtl-examples/ $CLOUD_CONF_DIR
ADD config-hdfs/hdfs-client.xml $CLOUD_CONF_DIR
ADD config-hdfs/core-site.xml $HADOOP_CONF
ADD config-hdfs/hdfs-site.xml $HADOOP_CONF

ENV CLOUD_CONF_PATH $CLOUD_CONF_DIR/cloud_rtl.ini.local
ENV LIBHDFS3_CONF $CLOUD_CONF_DIR/hdfs-client.xml

# Setup dev tools

# Build libomptarget
RUN git clone git://github.com/ompcloud/libomptarget.git $LIBOMPTARGET_SRC
RUN mkdir $LIBOMPTARGET_BUILD; cd $LIBOMPTARGET_BUILD; cmake -DCMAKE_BUILD_TYPE=Debug $LIBOMPTARGET_SRC; make -j2

# Prebuild Unibench
RUN git clone git://github.com/ompcloud/UniBench.git $UNIBENCH_SRC
#RUN export CC=$LLVM_BUILD/bin/clang; mkdir $UNIBENCH_BUILD; cd $UNIBENCH_BUILD; cmake $UNIBENCH_SRC -DCMAKE_BUILD_TYPE=Release

# Build llvm/clang
RUN git clone --depth 100 git://github.com/ompcloud/llvm.git $LLVM_SRC
RUN git clone --depth 100 git://github.com/ompcloud/clang.git $CLANG_SRC
RUN mkdir $LLVM_BUILD; cd $LLVM_BUILD; cmake $LLVM_SRC -DLLVM_TARGETS_TO_BUILD="X86" -DCMAKE_BUILD_TYPE=Release;
#make clang -j2

ADD scripts/ $CLOUD_CONF_DIR
RUN chmod +x $CLOUD_CONF_DIR/ompcloud-quicktests.sh $CLOUD_CONF_DIR/ompcloud-updatetools.sh

ENV TERM xterm

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

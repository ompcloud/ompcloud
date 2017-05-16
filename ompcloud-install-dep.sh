#!/bin/bash
set -e

SUDO=''
if (( $EUID != 0 )); then
  SUDO='sudo'
fi

# Install needed package
$SUDO apt-get update && \
  $SUDO apt-get install -y apt-utils apt-transport-https

$SUDO apt-get clean all && \
  $SUDO apt-get update && \
  $SUDO apt-get upgrade -y

# Default Java 9 does not seem to be compatible with SBT
$SUDO apt-get install -y gcc g++ cmake libxml2-dev uuid-dev \
  libprotobuf-dev protobuf-compiler libgsasl7-dev libkrb5-dev \
  libboost-all-dev libssh-dev libelf-dev libffi-dev git \
  openssh-server openjdk-8-jre-headless wget python-pip libomp-dev

sbt_list="/etc/apt/sources.list.d/sbt.list"
if [ -f "$sbt_list" ]
then
	echo "Sbt repository is already in apt sources list."
else
  echo "deb https://dl.bintray.com/sbt/debian /" | $SUDO tee -a $sbt_list
  $SUDO apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
  $SUDO apt-get update
fi
$SUDO apt-get install -y sbt

$SUDO pip install s3cmd

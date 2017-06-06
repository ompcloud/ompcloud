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
$SUDO apt-get install -y libxml2-dev uuid-dev \
  libprotobuf-dev protobuf-compiler libgsasl7-dev libkrb5-dev \
  libssh-dev libelf-dev libffi-dev \
  openjdk-8-jre-headless python-pip

# Install sbt after java to avoid configuration error
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

# Install Azure CLI 2.0
az_list="/etc/apt/sources.list.d/azure-cli.list"
if [ -f "$az_list" ]
then
	echo "Azure CLI repository is already in apt sources list."
else
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     $SUDO tee $az_list
  $SUDO apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
  $SUDO apt-get update
fi
$SUDO apt-get install -y azure-cli

$SUDO pip install s3cmd

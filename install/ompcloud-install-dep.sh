#!/bin/bash
set -e

SUDO=''
if (( $EUID != 0 )); then
  SUDO='sudo'
fi

# Install needed package
if [ -n "$(command -v apt-get)" ]
then
  $SUDO apt-get update && \
    $SUDO apt-get install -y apt-utils apt-transport-https

  $SUDO apt-get clean all && \
    $SUDO apt-get update && \
    $SUDO apt-get upgrade -y

  if [[ `lsb_release -rs` == "14.04" ]]
  then
    # Java 8 is not in ubuntu 14.04 official repository
    $SUDO add-apt-repository -y ppa:openjdk-r/ppa
    $SUDO apt-get update
    # fix error certification: https://github.com/sbt/sbt/issues/2536#issuecomment-284153103
    $SUDO /var/lib/dpkg/info/ca-certificates-java.postinst configure
  fi

  # Default Java 9 does not seem to be compatible with SBT
  $SUDO apt-get install -y libxml2-dev uuid-dev \
    libgsasl7-dev libkrb5-dev \
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

elif [ -n "$(command -v yum)" ]
then
  $SUDO yum -y install libxml2-devel uuid-devel protobuf-devel libgsasl-devel \
    boost-devel libssh-devel libffi-devel krb5-devel elfutils-libelf-devel \
    java-1.8.0-openjdk-headless python-pip

  sbt_repo="/etc/yum.repos.d/bintray-sbt-rpm.repo"
  if [ -f "$sbt_repo" ]
  then
    echo "Sbt repository is already in yum repo list."
  else
    curl https://bintray.com/sbt/rpm/rpm | $SUDO tee $sbt_repo
    $SUDO yum -y install sbt
  fi

  $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc
  az_repo="/etc/yum.repos.d/azure-cli.repo"
  if [ -f "$az_repo" ]
  then
    echo "Azure CLI repository is already in yum repo list."
  else
    printf "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | \
      $SUDO tee -a $az_repo
  fi
  yum list updates
  $SUDO yum -y install azure-cli

else
  echo "Your package manager is not yet supported by this script."
fi

$SUDO pip install s3cmd

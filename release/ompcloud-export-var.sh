#!/bin/bash

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

# Directory of the script
BASEDIR=$(dirname "$BASH_SOURCE")
REAL_BASEDIR="$(realpath $BASEDIR)"

# Set system environment variables
export PATH="$REAL_BASEDIR/sbin:$REAL_BASEDIR/bin:$PATH"
export LIBRARY_PATH="$REAL_BASEDIR/lib:$LIBRARY_PATH"
export LD_LIBRARY_PATH="$REAL_BASEDIR/lib:$LD_LIBRARY_PATH"
export CPATH="$REAL_BASEDIR/include:$CPATH"

# Set OmpCloud environment variables
export OMPCLOUD_CONF_PATH="$REAL_BASEDIR/conf/cloud_local.ini"
export LIBHDFS3_CONF="$REAL_BASEDIR/conf/hdfs-client.xml"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "ERROR this script need to be sourced"
  echo "Run 'source $BASEDIR/ompcloud-export-var.sh'"
else
  echo "OmpCloud env variables exported for the current shell session"
  echo "Note it needs to be re-run for future shell session"
fi

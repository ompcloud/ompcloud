#!/bin/bash

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

# Directory of the script
BASEDIR=$(dirname "$BASH_SOURCE")
REAL_BASEDIR="$(realpath $BASEDIR)"

# Set system environment variables
export PATH="$REAL_BASEDIR/sbin:$REAL_BASEDIR/bin:$PATH"
export LIBRARY_PATH="$REAL_BASEDIR/lib:$LIBRARY_PATH"
export LD_LIBRARY_PATH="$REAL_BASEDIR/lib:$LD_LIBRARY_PATH"

# Set OmpCloud environment variables
export OMPCLOUD_CONF_PATH="$REAL_BASEDIR/conf/cloud_rtl.ini.local"
export LIBHDFS3_CONF="$REAL_BASEDIR/conf/hdfs-client.xml"

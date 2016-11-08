#!/bin/bash
# Run quick tests for ompcloud

# Initialize HDFS server
hdfs-reset

# Build supported Unibench
export UNIBENCH_BUILD_TEST=/opt/Unibench-build-test
export CC=$LLVM_BUILD/bin/clang
mkdir $UNIBENCH_BUILD_TEST
cd $UNIBENCH_BUILD_TEST
cmake $UNIBENCH_SRC -DCMAKE_BUILD_TYPE=Release -DRUN_TEST=ON
make supported

# Run experiments
#ctest -I 2,2,,2,6,21,23,27,29,33,34
#ctest -I 2,2,,2,6,21,29,33,34 --output-on-failure
ctest --output-on-failure

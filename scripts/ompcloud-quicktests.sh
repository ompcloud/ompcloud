#!/bin/bash
# Run quick tests for ompcloud

UNIBENCH_BUILD_TEST="/opt/Unibench-build-test"
TESTED_CC="$LLVM_BUILD/bin/clang"

DOCKER=false
QUICK=false
RESET=true

while [[ $# -ge 1 ]]
do
  key="$1"

  case $key in
    -d|--docker)
    DOCKER=true
    ;;
    -q|--quick)
    QUICK=true
    ;;
    -n|--noreset)
    RESET=false
    ;;
    *)
    # unknown option
    ;;
  esac
  shift # past argument or value
done

export UNIBENCH_BUILD_TEST=$UNIBENCH_BUILD_TEST
export CC=$TESTED_CC

if [ "$RESET" = true ]; then
  echo "-- RESET OLD EXECUTION --"
  # Initialize HDFS server
  hdfs-reset
  rm -rf $UNIBENCH_BUILD_TEST
fi

# Build Unibench
mkdir -p $UNIBENCH_BUILD_TEST
cd $UNIBENCH_BUILD_TEST
cmake $UNIBENCH_SRC -DCMAKE_BUILD_TYPE=Release -DRUN_TEST=ON
make supported

# Run experiments
if [ "$DOCKER" = true ]; then
  ctest -I 1,1,,1,2,4,5,6,7,8,13,15,17,18 --output-on-failure
elif [ "$QUICK" = true ]; then
  ctest -R "mgBench_mat-mul" --output-on-failure
else
  ctest --output-on-failure
fi

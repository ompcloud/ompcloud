#!/bin/bash
# Run quick tests for ompcloud

# Any subsequent commands which fail will cause the script to exit immediately
set -e

UNIBENCH_BUILD_TEST="$OMPCLOUD_INSTALL_DIR/Unibench-build-test"
TESTED_CC="$OMPCLOUD_INSTALL_DIR/llvm-build/bin/clang"
TEST_LIST="2,2,,2,4,5,6,7,8,15,16,18"

QUICK=false
RESET=true

while [[ $# -ge 1 ]]
do
  key="$1"

  case $key in
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

export CC=$TESTED_CC

if [ "$RESET" = true ]; then
  echo "-- RESET OLD EXECUTION --"
  rm -rf $UNIBENCH_BUILD_TEST
fi

# Build Unibench
mkdir -p $UNIBENCH_BUILD_TEST
cd $UNIBENCH_BUILD_TEST
cmake $OMPCLOUD_INSTALL_DIR/Unibench -DCMAKE_BUILD_TYPE=Release -DRUN_TEST=ON

if [ "$QUICK" = true ]; then
  make mat-mul
else
  make supported
fi

# Run experiments
if [ "$QUICK" = true ]; then
  ctest -R "mgBench_mat-mul" --output-on-failure
else
  ctest -I $TEST_LIST --output-on-failure
fi

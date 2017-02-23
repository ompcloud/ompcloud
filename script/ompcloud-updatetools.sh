#!/bin/bash
# Update ompcloud tools

# Any subsequent commands which fail will cause the script to exit immediately
set -e

# Update LLVM/Clang
echo "Update LLVM/Clang..."
cd $LLVM_SRC; git pull
cd $CLANG_SRC; git pull
cd $LLVM_BUILD; make clang

# Update libomptarget
echo "Update libomptarget..."
cd $LIBOMPTARGET_SRC; git pull
cd $LIBOMPTARGET_BUILD; make

# Update Unibench
echo "Update Unibench..."
cd $UNIBENCH_SRC; git pull

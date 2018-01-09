#!/bin/bash
# Update ompcloud tools

# Any subsequent commands which fail will cause the script to exit immediately
set -e

# Update LLVM/Clang
echo "Update LLVM/Clang..."
cd $OMPCLOUD_INSTALL_DIR/llvm; git pull
cd $OMPCLOUD_INSTALL_DIR/llvm/tools/clang; git pull
cd $OMPCLOUD_INSTALL_DIR/llvm-build; make clang

# Update libomptarget
echo "Update libomptarget..."
cd $OMPCLOUD_INSTALL_DIR/libomptarget; git pull
cd $OMPCLOUD_INSTALL_DIR/libomptarget-build; make

# Update Unibench
echo "Update Unibench..."
cd $OMPCLOUD_INSTALL_DIR/Unibench; git pull

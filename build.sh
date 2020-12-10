#!/bin/bash

# Simple main build file
# Just run ./build.sh

function cpp_check {
    COMMAND='cppcheck'
    red="\e[1;31m"
    green="\e[1;32m"
    blue="\e[1;34m"
    cyan="\e[1;36m"
    purple="\e[1;35m"
    yellow="\e[1;33m"
    gray="\e[1;30m"

    normal="\e[0m"

    # Errors, warnings, notes and compiler recipes
    error="s/(\(error\).*)/$(printf $red)\\1$(printf $normal)/i"
    warning="s/(\(warning\).*)/$(printf $yellow)\\1$(printf $normal)/i"
    style="s/(\(style\).*)/$(printf $blue)\\1$(printf $normal)/"
    compiler_recipe="s/^((gcc|g\+\+|clang)(.exe)? .*)/$(printf $gray)\\1$(printf $normal)/"

    command "cppcheck" "$@" 2>&1 | sed -ru -e "$warning" -e "$error" -e "$style" -e "$compiler_recipe"

    if [  $? -ne 0 ]; then
        print "Static analysis failed"
        exit -1
    fi

}

# Create build base dir
[ ! -d build ] && mkdir build

# Format all source files
python3 .format_all.py

# static analyze
cpp_check --enable=warning,missingInclude,unusedFunction \
    --suppress=missingIncludeSystem --inline-suppr \
    --error-exitcode=1 -USIGQUIT --quiet --inconclusive -v \
    -i cuse.c -i canbus/ -i build/ -i control/LabJack/liblabjackusb \
    -i u3.c -I modbus/private -I client/include -I modbus/include -I relay/include \
    -I control/LabJack -I control/LabJack/library/ . 

# build
cd build
cmake -DCMAKE_C_COMPILER=gcc-8 -DCMAKE_CXX_COMPILER=g++-8 -DCMAKE_BUILD_TYPE=${BUILDTYPE} ..
cmake --build .
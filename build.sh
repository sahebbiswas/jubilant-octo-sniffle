#!/bin/bash
# set -x

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


BUILD=1
CLEAN=0
HELP=0
ANALYZE=1
RELEASE=0
FORMAT=0
TOOLCHAIN=../toolchain.unix.cmake

CONTROL_ARGS=""

while getopts "hcrfwa" opt; do
    case $opt in 
    a) ANALYZE=1
    	BUILD=0;;
    c) CLEAN=1
     ANALYZE=0
       BUILD=0 ;;
    h) HELP=1;;
    r) CLEAN=1
    	ANALYZE=0
       FORMAT=1 
       RELEASE=1;;
    f) FORMAT=1
    	ANALYZE=0;;
    w) CONTROL_ARGS="$CONTROL_ARGS -DIgnoreWarnings=ON";;
    ?) HELP=1;;
    esac
done

if [ "$HELP" = "1" ]; then
    echo usage:
    echo --------------------------------------------
    echo $0 [hcrfa]
    echo "$0              Build"
    echo "$0 -c           Clean the build folders"
    echo "$0 -a           Analyze files"
    echo "$0 -f           Format all source files and build code"
    echo "$0 -h           show this HELP"
    echo "$0 -r           Clean, format and rebuild, builds non-debug"
    echo "$0 -w           Ignore Build warnings"
    echo --------------------------------------------
    exit
fi

if [ "$CLEAN" = "1" ]; then
    echo "Clean all build folders"
    rm -rf build
fi
if [ "$FORMAT" = "1" ]; then
    echo Format all code
    python3 ".format_all.py"
fi

if [ "$ANALYZE" = "1" ]; then
	cpp_check --enable=warning,missingInclude,unusedFunction \
        --suppress=missingIncludeSystem \
        --inline-suppr --error-exitcode=1 \
        -USIGQUIT --quiet --inconclusive -v .
fi

if [ "$BUILD" = "1" ]; then
    
    python3 ".commit_check.py"
    echo "Build"
    [ ! -d build ] && mkdir build
    cd build
    
    BUILDTYPE=Debug
    
    if [ "$RELEASE" = "1" ]; then
        BUILDTYPE=Release
    fi

    cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN} -DCMAKE_BUILD_TYPE=${BUILDTYPE} ${CONTROL_ARGS} .. 
    cmake --build .  -- -j 4
fi

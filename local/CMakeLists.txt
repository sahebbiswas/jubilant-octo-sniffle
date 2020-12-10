file(GLOB SOURCES "*.cpp")

add_executable(listener ${SOURCES})
set( VERSION_MAJOR 1)
set( VERSION_MINOR 6)

set_target_properties(listener PROPERTIES VERSION ${VERSION_MAJOR}.${VERSION_MINOR})


FILE(WRITE ${CMAKE_BINARY_DIR}/build_version.h.in
"\#pragma once\n\n"
"\#define VERSION_MAJOR @LISTENER_VERSION_MAJOR@\n"
"\#define VERSION_MINOR @LISTENER_VERSION_MINOR@\n\n"
"\#define VERSION_BUILD @BVERSION@\n"
)

FILE(WRITE ${CMAKE_BINARY_DIR}/bversion.cmake
"
set(LISTENER_VERSION_MAJOR ${VERSION_MAJOR})
set(LISTENER_VERSION_MINOR ${VERSION_MINOR})
EXECUTE_PROCESS(
     COMMAND date +\"%y%m%d\"
     OUTPUT_VARIABLE BVERSION
     OUTPUT_STRIP_TRAILING_WHITESPACE
 )
 CONFIGURE_FILE(\${SRC} \${DST} @ONLY)
")

INCLUDE_DIRECTORIES(${CMAKE_BINARY_DIR})


ADD_CUSTOM_TARGET(
    build_version
    ${CMAKE_COMMAND} -D SRC=${CMAKE_BINARY_DIR}/build_version.h.in
                     -D DST=${CMAKE_BINARY_DIR}/build_version.h
                     -P ${CMAKE_BINARY_DIR}/bversion.cmake
)
ADD_DEPENDENCIES(listener build_version)

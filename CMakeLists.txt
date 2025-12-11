cmake_minimum_required(VERSION 3.15)

project(Satell
    VERSION 5.5.0
    DESCRIPTION "Satell - A Lua language superset"
    LANGUAGES C CXX
)

# Set C standard for Lua core
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Set C++ standard for Satell extensions
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build options
option(SATELL_BUILD_COMPILER "Build the Satell compiler" ON)
option(SATELL_BUILD_SHARED "Build Satell as a shared library" OFF)
option(SATELL_USE_READLINE "Use readline library for interactive mode" ON)
option(SATELL_ENABLE_TESTS "Enable internal testing support" OFF)

# Platform detection
if(UNIX AND NOT APPLE)
    set(SATELL_USE_LINUX ON)
    set(PLATFORM_LIBS m dl)
elseif(APPLE)
    set(SATELL_USE_MACOSX ON)
    set(PLATFORM_LIBS m)
elseif(WIN32)
    set(SATELL_USE_WINDOWS ON)
    set(PLATFORM_LIBS "")
endif()

# C Compiler warnings (for Lua core C files)
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    set(C_WARNINGS
        -Wall
        -Wextra
        -Wshadow
        -Wundef
        -Wwrite-strings
        -Wredundant-decls
        -Wdisabled-optimization
        -Wdouble-promotion
        -Wmissing-declarations
        -Wconversion
        -Wdeclaration-after-statement
        -Wmissing-prototypes
        -Wnested-externs
        -Wstrict-prototypes
        -Wold-style-definition
    )

    if(CMAKE_C_COMPILER_ID MATCHES "GNU")
        list(APPEND C_WARNINGS
            -Wlogical-op
            -Wno-aggressive-loop-optimizations
        )
    endif()
endif()

# C++ Compiler warnings (for Satell C++ extensions)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    set(CXX_WARNINGS
        -Wall
        -Wextra
        -Wshadow
        -Wundef
        -Wwrite-strings
        -Wredundant-decls
        -Wdisabled-optimization
        -Wdouble-promotion
        -Wconversion
        -Wnon-virtual-dtor
        -Woverloaded-virtual
    )

    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        list(APPEND CXX_WARNINGS
            -Wlogical-op
        )
    endif()
endif()

# Define platform macros
# Note: Don't use add_compile_definitions here because luaconf.h already defines these
# We'll add them as target-specific compile definitions to avoid redefinition warnings

# Core Satell library sources (Lua C code)
set(SATELL_CORE_SRC
    src/lapi.c
    src/lcode.c
    src/lctype.c
    src/ldebug.c
    src/ldo.c
    src/ldump.c
    src/lfunc.c
    src/lgc.c
    src/llex.c
    src/lmem.c
    src/lobject.c
    src/lopcodes.c
    src/lparser.c
    src/lstate.c
    src/lstring.c
    src/ltable.c
    src/ltm.c
    src/lundump.c
    src/lvm.c
    src/lzio.c
)

# Auxiliary library sources
set(SATELL_AUX_SRC
    src/lauxlib.c
)

# Standard library sources
set(SATELL_LIB_SRC
    src/lbaselib.c
    src/ldblib.c
    src/liolib.c
    src/lmathlib.c
    src/loslib.c
    src/ltablib.c
    src/lstrlib.c
    src/lutf8lib.c
    src/loadlib.c
    src/lcorolib.c
    src/linit.c
)

# Satell C++ extensions (add your C++ files here)
set(SATELL_CXX_SRC
    # Example C++ extensions
    src/satell_extensions.cpp
    # Add more C++ extension files here
)

# Add tests support if enabled
if(SATELL_ENABLE_TESTS)
    list(APPEND SATELL_CORE_SRC src/ltests.c)
    add_compile_definitions(LUA_USER_H="ltests.h")
endif()

# Create Satell library (static by default, shared if option enabled)
if(SATELL_BUILD_SHARED)
    add_library(libsatell SHARED
        ${SATELL_CORE_SRC}
        ${SATELL_AUX_SRC}
        ${SATELL_LIB_SRC}
        ${SATELL_CXX_SRC}
    )
    set_target_properties(libsatell PROPERTIES
        OUTPUT_NAME satell
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    )
else()
    add_library(libsatell STATIC
        ${SATELL_CORE_SRC}
        ${SATELL_AUX_SRC}
        ${SATELL_LIB_SRC}
        ${SATELL_CXX_SRC}
    )
    set_target_properties(libsatell PROPERTIES OUTPUT_NAME satell)
endif()

# Apply C warnings to C source files
set_source_files_properties(
    ${SATELL_CORE_SRC}
    ${SATELL_AUX_SRC}
    ${SATELL_LIB_SRC}
    PROPERTIES COMPILE_OPTIONS "${C_WARNINGS}"
)

# Apply C++ warnings to C++ source files
if(SATELL_CXX_SRC)
    set_source_files_properties(
        ${SATELL_CXX_SRC}
        PROPERTIES COMPILE_OPTIONS "${CXX_WARNINGS}"
    )
endif()

# Set include directories for the library
target_include_directories(libsatell
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<INSTALL_INTERFACE:include>
)

# Link platform libraries
target_link_libraries(libsatell PUBLIC ${PLATFORM_LIBS})

# Define platform macros only if not already defined in luaconf.h
# This avoids the redefinition warning
if(SATELL_USE_LINUX)
    target_compile_definitions(libsatell PRIVATE LUA_USE_LINUX)
elseif(SATELL_USE_MACOSX)
    target_compile_definitions(libsatell PRIVATE LUA_USE_MACOSX)
elseif(SATELL_USE_WINDOWS)
    # Windows is auto-detected in luaconf.h, so we don't need to define it
    # target_compile_definitions(libsatell PRIVATE LUA_USE_WINDOWS)
endif()

# If we have C++ sources, we need to link C++ standard library
if(SATELL_CXX_SRC)
    target_link_libraries(libsatell PUBLIC ${CMAKE_CXX_IMPLICIT_LINK_LIBRARIES})
endif()

# Satell interpreter executable
add_executable(satell src/lua.c)
target_link_libraries(satell PRIVATE libsatell)
set_source_files_properties(src/lua.c PROPERTIES COMPILE_OPTIONS "${C_WARNINGS}")

# Add readline support if available and requested
if(SATELL_USE_READLINE AND UNIX)
    find_library(READLINE_LIBRARY readline)
    if(READLINE_LIBRARY)
        target_link_libraries(satell PRIVATE ${READLINE_LIBRARY})
        target_compile_definitions(satell PRIVATE LUA_USE_READLINE)
    endif()
endif()

# Export compile commands for IDE support
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Installation rules
include(GNUInstallDirs)

install(TARGETS libsatell satell
    EXPORT SatellTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install headers
install(FILES
    src/lua.h
    src/luaconf.h
    src/lualib.h
    src/lauxlib.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Export targets for use by other CMake projects
install(EXPORT SatellTargets
    FILE SatellTargets.cmake
    NAMESPACE Satell::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/Satell
)

# Create config file for find_package support
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/SatellConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/SatellConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/SatellConfig.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/Satell
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/SatellConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/SatellConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/Satell
)

# Print configuration summary
message(STATUS "")
message(STATUS "Satell Configuration Summary")
message(STATUS "============================")
message(STATUS "Version:              ${PROJECT_VERSION}")
message(STATUS "Build type:           ${CMAKE_BUILD_TYPE}")
message(STATUS "C Compiler:           ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
message(STATUS "C++ Compiler:         ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "C++ Standard:         C++${CMAKE_CXX_STANDARD}")
message(STATUS "Install prefix:       ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Build shared library: ${SATELL_BUILD_SHARED}")
message(STATUS "Enable tests:         ${SATELL_ENABLE_TESTS}")
if(UNIX)
    message(STATUS "Use readline:         ${SATELL_USE_READLINE}")
endif()
message(STATUS "Platform libraries:   ${PLATFORM_LIBS}")
if(SATELL_CXX_SRC)
    message(STATUS "C++ extensions:       ${SATELL_CXX_SRC}")
else()
    message(STATUS "C++ extensions:       (none yet)")
endif()
message(STATUS "")

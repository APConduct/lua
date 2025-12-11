cmake_minimum_required(VERSION 3.15)

project(LuaSatell
    VERSION 5.5.0
    DESCRIPTION "Lua Satell - A Lua language superset"
    LANGUAGES C
)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Build options
option(LUA_BUILD_COMPILER "Build the Lua compiler (luac)" ON)
option(LUA_BUILD_SHARED "Build Lua as a shared library" OFF)
option(LUA_USE_READLINE "Use readline library for interactive mode" ON)
option(LUA_ENABLE_TESTS "Enable internal testing support" OFF)

# Platform detection
if(UNIX AND NOT APPLE)
    set(LUA_USE_LINUX ON)
    set(PLATFORM_LIBS m dl)
elseif(APPLE)
    set(LUA_USE_MACOSX ON)
    set(PLATFORM_LIBS m)
elseif(WIN32)
    set(LUA_USE_WINDOWS ON)
    set(PLATFORM_LIBS "")
endif()

# Compiler warnings
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
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
        -Wc++-compat
        -Wold-style-definition
    )

    if(CMAKE_C_COMPILER_ID MATCHES "GNU")
        add_compile_options(
            -Wlogical-op
            -Wno-aggressive-loop-optimizations
        )
    endif()
endif()

# Define platform macros
if(LUA_USE_LINUX)
    add_compile_definitions(LUA_USE_LINUX)
elseif(LUA_USE_MACOSX)
    add_compile_definitions(LUA_USE_MACOSX)
elseif(LUA_USE_WINDOWS)
    add_compile_definitions(LUA_USE_WINDOWS)
endif()

# Core Lua library sources
set(LUA_CORE_SRC
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
set(LUA_AUX_SRC
    src/lauxlib.c
)

# Standard library sources
set(LUA_LIB_SRC
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

# Add tests support if enabled
if(LUA_ENABLE_TESTS)
    list(APPEND LUA_CORE_SRC src/ltests.c)
    add_compile_definitions(LUA_USER_H="ltests.h")
endif()

# Create Lua library (static by default, shared if option enabled)
if(LUA_BUILD_SHARED)
    add_library(liblua SHARED ${LUA_CORE_SRC} ${LUA_AUX_SRC} ${LUA_LIB_SRC})
    set_target_properties(liblua PROPERTIES
        OUTPUT_NAME lua
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    )
else()
    add_library(liblua STATIC ${LUA_CORE_SRC} ${LUA_AUX_SRC} ${LUA_LIB_SRC})
    set_target_properties(liblua PROPERTIES OUTPUT_NAME lua)
endif()

# Set include directories for the library
target_include_directories(liblua
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<INSTALL_INTERFACE:include>
)

# Link platform libraries
target_link_libraries(liblua PUBLIC ${PLATFORM_LIBS})

# Lua interpreter executable
add_executable(lua src/lua.c)
target_link_libraries(lua PRIVATE liblua)

# Add readline support if available and requested
if(LUA_USE_READLINE AND UNIX)
    find_library(READLINE_LIBRARY readline)
    if(READLINE_LIBRARY)
        target_link_libraries(lua PRIVATE ${READLINE_LIBRARY})
        target_compile_definitions(lua PRIVATE LUA_USE_READLINE)
    endif()
endif()

# Export compile commands for IDE support
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Installation rules
include(GNUInstallDirs)

install(TARGETS liblua lua
    EXPORT LuaSatellTargets
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
install(EXPORT LuaSatellTargets
    FILE LuaSatellTargets.cmake
    NAMESPACE LuaSatell::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/LuaSatell
)

# Create config file for find_package support
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/LuaSatellConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/LuaSatellConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/LuaSatellConfig.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/LuaSatell
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/LuaSatellConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/LuaSatellConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/LuaSatell
)

# Print configuration summary
message(STATUS "")
message(STATUS "Lua Satell Configuration Summary")
message(STATUS "================================")
message(STATUS "Version:              ${PROJECT_VERSION}")
message(STATUS "Build type:           ${CMAKE_BUILD_TYPE}")
message(STATUS "C Compiler:           ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
message(STATUS "Install prefix:       ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Build shared library: ${LUA_BUILD_SHARED}")
message(STATUS "Enable tests:         ${LUA_ENABLE_TESTS}")
if(UNIX)
    message(STATUS "Use readline:         ${LUA_USE_READLINE}")
endif()
message(STATUS "Platform libraries:   ${PLATFORM_LIBS}")
message(STATUS "")

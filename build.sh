#!/usr/bin/env bash
# Convenience build script for Satell

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BUILD_DIR="build"
BUILD_TYPE="Release"
INSTALL_PREFIX=""
CLEAN=false
INSTALL=false
RUN_SATELL=false
SHARED=false
TESTS=false
GENERATOR="Ninja"

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build Satell using CMake.

OPTIONS:
    -h, --help              Show this help message
    -d, --debug             Build in Debug mode (default: Release)
    -c, --clean             Clean build directory before building
    -i, --install           Install after building
    -p, --prefix PATH       Set installation prefix (default: /usr/local)
    -s, --shared            Build shared library instead of static
    -t, --tests             Enable internal testing support
    -r, --run               Run Satell interpreter after building
    -b, --build-dir DIR     Specify build directory (default: build)
    -j, --jobs N            Number of parallel build jobs (default: auto)
    -g, --generator GEN     CMake generator (default: Ninja, alt: "Unix Makefiles")

EXAMPLES:
    $0                      # Basic release build
    $0 -d -r                # Debug build and run
    $0 -c -i                # Clean, build, and install
    $0 -s -p /opt/satell    # Shared lib, custom prefix
    $0 -d -t                # Debug build with tests

EOF
    exit 0
}

# Print colored message
print_msg() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Parse command line arguments
JOBS=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -d|--debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -i|--install)
            INSTALL=true
            shift
            ;;
        -p|--prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        -s|--shared)
            SHARED=true
            shift
            ;;
        -t|--tests)
            TESTS=true
            shift
            ;;
        -r|--run)
            RUN_SATELL=true
            shift
            ;;
        -b|--build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -g|--generator)
            GENERATOR="$2"
            shift 2
            ;;
        *)
            print_msg "$RED" "Unknown option: $1"
            usage
            ;;
    esac
done

# Clean if requested
if [ "$CLEAN" = true ]; then
    print_msg "$YELLOW" "Cleaning build directory: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

# Create build directory
print_msg "$BLUE" "Creating build directory: $BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Prepare CMake arguments
CMAKE_ARGS="-G \"$GENERATOR\" -DCMAKE_BUILD_TYPE=$BUILD_TYPE"

if [ -n "$INSTALL_PREFIX" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX"
fi

if [ "$SHARED" = true ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DSATELL_BUILD_SHARED=ON"
fi

if [ "$TESTS" = true ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DSATELL_ENABLE_TESTS=ON"
fi

# Configure
print_msg "$BLUE" "Configuring project..."
print_msg "$BLUE" "Generator: $GENERATOR"
print_msg "$BLUE" "CMake args: $CMAKE_ARGS"
eval cmake -B "$BUILD_DIR" $CMAKE_ARGS

# Build
print_msg "$GREEN" "Building..."
if [ -n "$JOBS" ]; then
    cmake --build "$BUILD_DIR" -j "$JOBS"
else
    cmake --build "$BUILD_DIR"
fi

print_msg "$GREEN" "Build completed successfully!"

# Install if requested
if [ "$INSTALL" = true ]; then
    print_msg "$BLUE" "Installing..."
    if [ -n "$INSTALL_PREFIX" ]; then
        cmake --install "$BUILD_DIR"
    else
        sudo cmake --install "$BUILD_DIR"
    fi
    print_msg "$GREEN" "Installation completed!"
fi

# Run if requested
if [ "$RUN_SATELL" = true ]; then
    print_msg "$BLUE" "Running Satell interpreter..."
    echo ""
    "$BUILD_DIR/satell" -v
    echo ""
    print_msg "$GREEN" "Type 'os.exit()' or press Ctrl+D to exit"
    "$BUILD_DIR/satell"
fi

print_msg "$GREEN" "All done!"

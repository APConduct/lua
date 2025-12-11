# Building Satell

This document describes how to build Satell from source using CMake.

## Prerequisites

- **CMake** 3.15 or higher
- **C99-compatible C compiler** (GCC, Clang, MSVC, etc.)
- **Ninja** build system (recommended) or **Make**

### Installing Prerequisites

#### MSYS2 (Windows)
```bash
pacman -S mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja
```

#### macOS
```bash
brew install cmake ninja
```

#### Linux (Debian/Ubuntu)
```bash
sudo apt-get install build-essential cmake ninja-build
```

### Optional Dependencies

- **readline** library (Linux/macOS only) - for enhanced interactive mode with line editing and history

## Quick Start

### Linux/macOS/MSYS2

```bash
# Create a build directory
mkdir build
cd build

# Configure the project with Ninja
cmake -G Ninja ..

# Build
ninja

# Run Satell
./satell

# (Optional) Install system-wide
sudo cmake --install .
```

Or use the convenience script:

```bash
./build.sh           # Basic release build
./build.sh -d -r     # Debug build and run
```

### Windows

```batch
REM Create a build directory
mkdir build
cd build

REM Configure the project
cmake ..

REM Build
cmake --build . --config Release

REM Run Satell
Release\satell.exe

REM (Optional) Install
cmake --install . --prefix C:\Satell
```

## Build Options

Satell provides several CMake options to customize the build:

| Option | Default | Description |
|--------|---------|-------------|
| `SATELL_BUILD_SHARED` | OFF | Build Satell as a shared library instead of static |
| `SATELL_USE_READLINE` | ON | Enable readline support for interactive mode (Unix only) |
| `SATELL_ENABLE_TESTS` | OFF | Enable internal testing support (for development) |

### Example: Building with Custom Options

```bash
cmake -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DSATELL_BUILD_SHARED=ON \
    -DSATELL_USE_READLINE=OFF

ninja -C build
```

Or:

```bash
./build.sh -s --prefix /opt/satell
```

## Build Types

CMake supports different build types:

- **Debug** - No optimization, debug symbols included
- **Release** - Full optimization, no debug symbols
- **RelWithDebInfo** - Optimization with debug symbols
- **MinSizeRel** - Optimize for size

Set the build type during configuration:

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
```

## Installation

By default, Lua Satell installs to:
- Linux: `/usr/local`
- Windows: `C:\Program Files\LuaSatell`
- macOS: `/usr/local`

To change the installation prefix:

```bash
cmake -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/custom/path
ninja -C build
cmake --install build
```

### What Gets Installed

- `bin/satell` - The Satell interpreter
- `lib/libsatell.a` (or `.so`/`.dll`) - The Satell library
- `include/lua.h`, `luaconf.h`, `lualib.h`, `lauxlib.h` - Headers
- `lib/cmake/Satell/` - CMake package files

## Using Satell in Your CMake Project

After installation, you can use Satell in your own CMake projects:

```cmake
find_package(Satell REQUIRED)

add_executable(myapp main.c)
target_link_libraries(myapp PRIVATE Satell::libsatell)
```

## Cross-Compilation

To cross-compile for a different target, specify a toolchain file:

```bash
cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=/path/to/toolchain.cmake
ninja -C build
```

## Troubleshooting

### Readline Not Found

If CMake cannot find the readline library on Linux/macOS:

```bash
# Debian/Ubuntu
sudo apt-get install libreadline-dev

# Fedora/RHEL
sudo dnf install readline-devel

# macOS with Homebrew
brew install readline
cmake -B build -G Ninja -DCMAKE_PREFIX_PATH=$(brew --prefix readline)
```

### Compiler Warnings

The build is configured with strict warnings. To treat warnings as errors:

```bash
cmake -B build -G Ninja -DCMAKE_C_FLAGS="-Werror"
```

### Out-of-Source Builds

Always use out-of-source builds (build directory separate from source):

```bash
# Good ✓
mkdir build && cd build
cmake -G Ninja ..

# Bad ✗ (pollutes source directory)
cmake .
```

## Development Builds

For development with internal tests enabled:

```bash
cmake -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DSATELL_ENABLE_TESTS=ON

ninja -C build
```

Or:

```bash
./build.sh -d -t
```

## IDE Support

CMake generates `compile_commands.json` which is used by many IDEs and tools:

- **Visual Studio Code**: Install the CMake Tools extension
- **CLion**: Opens CMake projects natively
- **Visual Studio**: Use "Open Folder" with CMake support
- **Vim/Neovim**: Use with LSP clients (clangd, ccls)

## Cleaning the Build

To clean build artifacts:

```bash
# Remove the entire build directory (recommended)
rm -rf build

# Or use Ninja
ninja -C build -t clean
```

## Additional Resources

- [CMake Documentation](https://cmake.org/documentation/)
- [Original Lua Build Instructions](https://www.lua.org/manual/5.4/readme.html)
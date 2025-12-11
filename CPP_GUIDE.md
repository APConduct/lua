# Using C++ in Satell

This guide explains how to add C++23 features to your Satell project while maintaining the Lua core in C.

## Architecture Overview

Satell uses a **mixed C/C++ architecture**:

- **Lua Core** (C99): The original Lua VM, parser, and runtime remain in C for compatibility and performance
- **Satell Extensions** (C++23): New features and enhancements are written in modern C++

This approach gives you:
- ✅ Full access to modern C++ features (C++23)
- ✅ Compatibility with existing Lua C API
- ✅ Performance of C for the core VM
- ✅ Expressiveness of C++ for new features

## Project Structure

```
src/
├── lapi.c, lcode.c, ...      # Lua core (C)
├── lauxlib.c                  # Lua auxiliary library (C)
├── lbaselib.c, liolib.c, ...  # Lua standard libraries (C)
├── lua.c                      # Interpreter main (C)
├── satell_extensions.cpp      # Example C++ extensions
└── your_feature.cpp           # Your C++ extensions
```

## Adding a New C++ Extension

### Step 1: Create Your C++ File

Create a new `.cpp` file in `src/`:

```cpp
// src/my_feature.cpp
#include <string>
#include <vector>

// Lua headers must be in extern "C" block
extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

namespace satell {

// Your C++ code here
static int my_function(lua_State* L) {
    // Use modern C++ features
    std::vector<std::string> data{"Hello", "from", "C++23"};
    
    lua_createtable(L, data.size(), 0);
    for (size_t i = 0; i < data.size(); i++) {
        lua_pushstring(L, data[i].c_str());
        lua_rawseti(L, -2, i + 1);
    }
    return 1;
}

static const luaL_Reg mylib[] = {
    {"my_function", my_function},
    {nullptr, nullptr}
};

} // namespace satell

// Export with C linkage
extern "C" {
LUAMOD_API int luaopen_myfeature(lua_State* L) {
    luaL_newlib(L, satell::mylib);
    return 1;
}
}
```

### Step 2: Add to CMakeLists.txt

Edit `CMakeLists.txt` and add your file to `SATELL_CXX_SRC`:

```cmake
set(SATELL_CXX_SRC
    src/satell_extensions.cpp
    src/my_feature.cpp           # Add your file here
)
```

### Step 3: Build

```bash
cmake -G Ninja -B build
ninja -C build
```

### Step 4: Use in Lua

```lua
local myfeature = require("myfeature")
local result = myfeature.my_function()
-- Use result...
```

## C++ Features You Can Use

### C++23 Standard Library

```cpp
#include <string>
#include <vector>
#include <map>
#include <unordered_map>
#include <optional>
#include <variant>
#include <string_view>
#include <ranges>
#include <algorithm>
#include <memory>
#include <filesystem>
```

### Example: Using Modern C++ Features

```cpp
#include <ranges>
#include <algorithm>

namespace satell {

static int filter_numbers(lua_State* L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    int threshold = luaL_checkinteger(L, 2);
    
    // Use C++20 ranges
    std::vector<int> numbers;
    lua_pushnil(L);
    while (lua_next(L, 1)) {
        numbers.push_back(lua_tointeger(L, -1));
        lua_pop(L, 1);
    }
    
    auto filtered = numbers 
        | std::views::filter([threshold](int n) { return n > threshold; })
        | std::ranges::to<std::vector>();
    
    // Return as Lua table
    lua_createtable(L, filtered.size(), 0);
    for (size_t i = 0; i < filtered.size(); i++) {
        lua_pushinteger(L, filtered[i]);
        lua_rawseti(L, -2, i + 1);
    }
    return 1;
}

} // namespace satell
```

## Best Practices

### 1. Always Use `extern "C"` for Lua API Functions

```cpp
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}

extern "C" {
LUAMOD_API int luaopen_yourlib(lua_State* L) {
    // Your code
}
}
```

### 2. Use Namespaces for C++ Code

```cpp
namespace satell {
    // All your C++ implementation
}

// Only the registration function needs C linkage
extern "C" {
    LUAMOD_API int luaopen_yourlib(lua_State* L) {
        luaL_newlib(L, satell::yourlib);
        return 1;
    }
}
```

### 3. Handle Exceptions Carefully

Lua's C API doesn't understand C++ exceptions. Always catch them:

```cpp
static int safe_cpp_function(lua_State* L) {
    try {
        // Your C++ code that might throw
        std::vector<int> data;
        data.at(1000);  // might throw std::out_of_range
    } catch (const std::exception& e) {
        return luaL_error(L, "C++ exception: %s", e.what());
    } catch (...) {
        return luaL_error(L, "Unknown C++ exception");
    }
    return 0;
}
```

### 4. Use RAII for Resource Management

```cpp
static int read_file(lua_State* L) {
    const char* filename = luaL_checkstring(L, 1);
    
    try {
        // RAII: file automatically closed
        std::ifstream file(filename);
        if (!file) {
            return luaL_error(L, "Cannot open file: %s", filename);
        }
        
        std::string content(
            (std::istreambuf_iterator<char>(file)),
            std::istreambuf_iterator<char>()
        );
        
        lua_pushlstring(L, content.data(), content.size());
        return 1;
        
    } catch (const std::exception& e) {
        return luaL_error(L, "File error: %s", e.what());
    }
}
```

### 5. Use Smart Pointers for Memory Management

```cpp
#include <memory>

namespace satell {

class MyClass {
public:
    MyClass(int value) : value_(value) {}
    int getValue() const { return value_; }
private:
    int value_;
};

static int create_object(lua_State* L) {
    int value = luaL_checkinteger(L, 1);
    
    // Use unique_ptr for automatic cleanup
    auto obj = std::make_unique<MyClass>(value);
    
    // Store in Lua userdata
    auto** udata = static_cast<std::unique_ptr<MyClass>**>(
        lua_newuserdata(L, sizeof(std::unique_ptr<MyClass>*))
    );
    *udata = new std::unique_ptr<MyClass>(std::move(obj));
    
    // Set metatable for garbage collection
    luaL_setmetatable(L, "MyClass");
    return 1;
}

} // namespace satell
```

## Performance Considerations

### When to Use C++

✅ **Good use cases:**
- Complex data structures (maps, sets, graphs)
- String processing with std::string
- File I/O with std::filesystem
- Modern algorithms from `<algorithm>` and `<ranges>`
- Type-safe code with templates
- RAII for resource management

❌ **Avoid C++ for:**
- Hot paths in the VM (keep in C)
- Simple operations (C is faster to compile)
- Code that needs to be inlined (templates can bloat binaries)

### Optimization Tips

1. **Use `std::string_view`** instead of `std::string` for read-only strings
2. **Reserve capacity** for vectors: `vec.reserve(expected_size)`
3. **Use `constexpr`** for compile-time computation
4. **Profile before optimizing** - measure, don't guess

## Example: Complete C++ Extension

See `src/satell_extensions.cpp` for a complete example that includes:
- String utilities with modern C++
- Error handling with exceptions
- Integration with Lua's type system
- Proper `extern "C"` linkage

To test it:

```bash
./build/satell examples/cpp_test.lua
```

## Troubleshooting

### Linker Errors

If you get undefined reference errors, ensure:
1. Your `.cpp` file is in `SATELL_CXX_SRC` in CMakeLists.txt
2. You're using `extern "C"` for Lua API functions
3. You've rebuilt: `ninja -C build`

### C++ Exceptions Not Caught

Never let C++ exceptions cross the C/Lua boundary. Always catch them in your C++ functions that are called from Lua.

### Name Mangling Issues

If Lua can't find your function:
- Check that `luaopen_*` is in an `extern "C"` block
- Verify the library name matches: `require("foo")` needs `luaopen_foo`

### Compilation Errors with C++23

If your compiler doesn't support C++23, edit `CMakeLists.txt`:

```cmake
set(CMAKE_CXX_STANDARD 20)  # or 17
```

## Further Reading

- [Lua C API Reference](https://www.lua.org/manual/5.4/manual.html#4)
- [C++23 Features](https://en.cppreference.com/w/cpp/23)
- Original Lua source: `src/l*.c` files
- Example extensions: `src/satell_extensions.cpp`

## Summary

The mixed C/C++ architecture lets you:
- Keep Lua's core fast and compatible (C)
- Add modern features with C++23
- Use RAII, templates, and the STL
- Write cleaner, safer code for extensions

Happy coding! 🚀
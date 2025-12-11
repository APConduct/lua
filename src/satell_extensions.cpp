/*
** $Id: satell_extensions.cpp $
** Satell C++ Extensions
** Example C++ features and extensions for Satell
*/

#include <string>
#include <vector>
#include <memory>
#include <optional>
#include <string_view>

// Lua headers need C linkage
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}

namespace satell {

/*
** Example: Modern C++ string utilities for Satell
*/
class StringUtils {
public:
    static std::optional<std::string> safe_concat(
        std::string_view a, 
        std::string_view b
    ) {
        try {
            return std::string(a) + std::string(b);
        } catch (const std::bad_alloc&) {
            return std::nullopt;
        }
    }

    static std::vector<std::string_view> split(
        std::string_view str, 
        char delimiter
    ) {
        std::vector<std::string_view> result;
        size_t start = 0;
        
        while (start < str.size()) {
            size_t end = str.find(delimiter, start);
            if (end == std::string_view::npos) {
                end = str.size();
            }
            result.push_back(str.substr(start, end - start));
            start = end + 1;
        }
        
        return result;
    }
};

/*
** Example Lua C API wrapper with C++
** This demonstrates how to expose C++ functionality to Lua
*/

// Example: satell.cpp_hello(name) -> string
static int cpp_hello(lua_State* L) {
    const char* name = luaL_checkstring(L, 1);
    
    // Use C++ features
    std::string greeting = "Hello from C++23, " + std::string(name) + "!";
    
    lua_pushstring(L, greeting.c_str());
    return 1;
}

// Example: satell.cpp_version() -> string
static int cpp_version(lua_State* L) {
    std::string version = "Satell C++ Extensions v1.0 (C++" 
                         + std::to_string(__cplusplus) 
                         + ")";
    
    lua_pushstring(L, version.c_str());
    return 1;
}

// Example: satell.split(string, delimiter) -> table
static int cpp_split(lua_State* L) {
    const char* str = luaL_checkstring(L, 1);
    const char* delim = luaL_checkstring(L, 2);
    
    if (delim[1] != '\0') {
        return luaL_error(L, "delimiter must be a single character");
    }
    
    auto parts = StringUtils::split(str, delim[0]);
    
    lua_createtable(L, static_cast<int>(parts.size()), 0);
    for (size_t i = 0; i < parts.size(); i++) {
        lua_pushlstring(L, parts[i].data(), parts[i].size());
        lua_rawseti(L, -2, static_cast<lua_Integer>(i + 1));
    }
    
    return 1;
}

// Registry of Satell C++ extension functions
static const luaL_Reg satell_cpplib[] = {
    {"cpp_hello", cpp_hello},
    {"cpp_version", cpp_version},
    {"split", cpp_split},
    {nullptr, nullptr}
};

} // namespace satell

/*
** Open Satell C++ extensions library
** This function is called from linit.c to register the extensions
*/
extern "C" {

LUAMOD_API int luaopen_satell_cpp(lua_State* L) {
    luaL_newlib(L, satell::satell_cpplib);
    return 1;
}

} // extern "C"
/*
** $Id: lprefix_cpp.h $
** C++ compatibility definitions for Lua/Satell
** See Copyright Notice in lua.h
*/

#ifndef lprefix_cpp_h
#define lprefix_cpp_h

/*
** This file is included before all other headers to ensure C++
** compatibility when compiling Lua's C code as C++.
*/

/* Include the original lprefix.h first */
#include "lprefix.h"

#ifdef __cplusplus

/* Ensure C linkage for Lua API functions */
#define LUA_API extern "C"
#define LUALIB_API extern "C"
#define LUAMOD_API extern "C"

/* C++ doesn't allow implicit void* conversions */
#define lua_pushlightuserdata(L,p) \
    lua_pushlightuserdata(L, static_cast<void*>(p))

/* Helper for common C++ compatibility issues */
#define cast_void(p) static_cast<void*>(p)
#define cast_voidp(p) static_cast<void*>(p)
#define cast_charp(p) static_cast<char*>(p)
#define cast_ucharp(p) static_cast<unsigned char*>(p)

/* Disable C-specific warnings that don't apply to C++ */
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wold-style-cast"
#pragma GCC diagnostic ignored "-Wzero-as-null-pointer-constant"
#endif

#endif /* __cplusplus */

#endif /* lprefix_cpp_h */
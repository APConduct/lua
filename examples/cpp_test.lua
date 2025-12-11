-- Example Lua script demonstrating Satell C++ extensions
-- This shows how to use C++ features from Lua

print("=== Satell C++ Extensions Demo ===\n")

-- Load the C++ extensions library
local satell_cpp = require("satell_cpp")

-- Test 1: C++ Hello function
print("Test 1: C++ Hello")
local greeting = satell_cpp.cpp_hello("Satell User")
print(greeting)
print()

-- Test 2: C++ Version info
print("Test 2: C++ Version")
local version = satell_cpp.cpp_version()
print(version)
print()

-- Test 3: String splitting with C++
print("Test 3: String Split")
local text = "Hello,World,From,C++,Extensions"
local parts = satell_cpp.split(text, ",")

print("Original string: " .. text)
print("Split into " .. #parts .. " parts:")
for i, part in ipairs(parts) do
    print("  [" .. i .. "] = '" .. part .. "'")
end
print()

-- Test 4: Another split example
print("Test 4: Path Split")
local path = "/usr/local/bin/satell"
local segments = satell_cpp.split(path, "/")

print("Path: " .. path)
print("Segments:")
for i, segment in ipairs(segments) do
    if segment ~= "" then
        print("  " .. segment)
    end
end
print()

print("=== Demo Complete ===")

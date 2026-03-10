cmake_minimum_required(VERSION 3.18)

project(llama_android)

# Include FetchContent to download llama.cpp
include(FetchContent)
FetchContent_Declare(
    llama
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_TAG        master
)

# Set common options
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Disable tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Disable examples" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Disable server" FORCE)

FetchContent_MakeAvailable(llama)

# Add our wrapper source
add_library(llama_wrapper SHARED 
    ../../../../../native/llama_wrapper.cpp
)

target_include_directories(llama_wrapper PRIVATE
    ../../../../../native
    ${llama_SOURCE_DIR}
    ${llama_SOURCE_DIR}/common
)

# Link against the main llama target
target_link_libraries(llama_wrapper
    llama
    log
)

# Rename to libllama.so to match Dart FFI expectation
set_target_properties(llama_wrapper PROPERTIES 
    C_VISIBILITY_PRESET default
    CXX_VISIBILITY_PRESET default
    VISIBILITY_INLINES_HIDDEN OFF
)

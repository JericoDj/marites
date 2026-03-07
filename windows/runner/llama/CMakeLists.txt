cmake_minimum_required(VERSION 3.14)

project(llama_windows)

# Enable Vulkan if available, falling back to CPU
option(GGML_VULKAN "Enable Vulkan support" OFF)
option(GGML_CUDA "Enable CUDA support" OFF)

include(FetchContent)
FetchContent_Declare(
    llama
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_TAG        master
)

set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Disable tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Disable examples" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Disable server" FORCE)

FetchContent_MakeAvailable(llama)

add_library(llama_wrapper SHARED 
    ../../../native/llama_wrapper.cpp
)

target_include_directories(llama_wrapper PRIVATE
    ../../../native
    ${llama_SOURCE_DIR}
    ${llama_SOURCE_DIR}/common
)

# Under Windows, building a DLL requires resolving symbols
target_link_libraries(llama_wrapper PRIVATE llama)

# Set output name to llama.dll
set_target_properties(llama_wrapper PROPERTIES OUTPUT_NAME "llama")

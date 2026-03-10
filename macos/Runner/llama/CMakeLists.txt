cmake_minimum_required(VERSION 3.14)

project(llama_macos)

# Set up macOS architecture (Apple Silicon support)
set(CMAKE_OSX_ARCHITECTURES "arm64")

# Enable Metal for Apple Silicon
set(GGML_USE_METAL ON)
set(LLAMA_METAL ON)

include(FetchContent)
FetchContent_Declare(
    llama
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_TAG        master
)

set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Disable tests" FORCE)
set(LLAMA_BUILD_COMMON ON CACHE BOOL "Enable common" FORCE)
set(LLAMA_BUILD_TOOLS ON CACHE BOOL "Enable tools" FORCE)
set(LLAMA_BUILD_EXAMPLES ON CACHE BOOL "Enable examples" FORCE)
set(LLAMA_BUILD_SERVER ON CACHE BOOL "Enable server" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "Disable cURL" FORCE)

FetchContent_MakeAvailable(llama)

add_library(llama_wrapper SHARED 
    ../../../native/llama_wrapper.cpp
)

target_include_directories(llama_wrapper PRIVATE
    ../../../native
    ${llama_SOURCE_DIR}
    ${llama_SOURCE_DIR}/common
)

target_link_libraries(llama_wrapper PRIVATE llama)

# Set output name to libllama.dylib
set_target_properties(llama_wrapper PROPERTIES OUTPUT_NAME "llama")

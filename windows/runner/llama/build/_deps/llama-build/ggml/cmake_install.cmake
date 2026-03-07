# Install script for directory: C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Program Files (x86)/llama_windows")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Debug")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/ggml/src/cmake_install.cmake")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/ggml/src/ggml.lib")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/bin/ggml.dll")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE FILE FILES
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-cpu.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-alloc.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-backend.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-blas.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-cann.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-cpp.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-cuda.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-opt.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-metal.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-rpc.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-virtgpu.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-sycl.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-vulkan.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-webgpu.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/ggml-zendnn.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/ggml/include/gguf.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/ggml/src/ggml-base.lib")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/bin/ggml-base.dll")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/ggml" TYPE FILE FILES
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/ggml/ggml-config.cmake"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/ggml/ggml-version.cmake"
    )
endif()


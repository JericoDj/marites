# Install script for directory: C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src

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
  include("C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/ggml/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/src/cmake_install.cmake")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/src/llama.lib")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/bin/llama.dll")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE FILE FILES
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/include/llama.h"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/include/llama-cpp.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/llama" TYPE FILE FILES
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/llama-config.cmake"
    "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/llama-version.cmake"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE FILE PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-src/convert_hf_to_gguf.py")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig" TYPE FILE FILES "C:/Users/dejes/StudioProjects/ ADA-AI-ASSISTANT/gemma_local_ai/windows/runner/llama/build/_deps/llama-build/llama.pc")
endif()


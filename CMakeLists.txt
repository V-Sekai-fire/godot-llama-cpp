cmake_minimum_required(VERSION 3.14)
project(godot-llama-cpp CXX)

# Build static libraries to reduce the number of separate .dylib files
set(BUILD_SHARED_LIBS OFF)

# Options for compute backends
option(ENABLE_METAL "Enable Metal compute backend" OFF)
option(ENABLE_VULKAN "Enable Vulkan compute backend" OFF)
option(ENABLE_CUDA "Enable CUDA compute backend" OFF)
option(ENABLE_CANN "Enable CANN compute backend" OFF)

# Set llama.cpp GGML options based on our options
if(ENABLE_METAL)
    set(GGML_METAL ON)
endif()
if(ENABLE_VULKAN)
    set(GGML_VULKAN ON)
endif()
if(ENABLE_CUDA)
    set(GGML_CUDA ON)
endif()
if(ENABLE_CANN)
    set(GGML_CANN ON)
endif()

# Enable llama common library (cache to pass to subproject)
set(LLAMA_BUILD_COMMON ON CACHE BOOL "Enable common library" FORCE)

# Disable CURL as it's not needed for the addon
set(LLAMA_CURL OFF CACHE BOOL "Disable CURL" FORCE)

# Force disable Metal completely
set(GGML_METAL OFF CACHE BOOL "Disable Metal GPU backend" FORCE)

# Default optimizations
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

# Add subdirectories (order matters for dependency tracking)
add_subdirectory(godot-cpp)
add_subdirectory(llama.cpp)

# Collect source files
file(GLOB SRC_FILES src/*.cpp)

# Create the shared library
add_library(godot_llama SHARED ${SRC_FILES})

target_include_directories(godot_llama PRIVATE
    src
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/src
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/common
)

# Link dependencies
target_link_libraries(godot_llama PRIVATE godot::cpp llama)

# Platform-specific linking
if(APPLE)
    target_link_libraries(godot_llama PRIVATE "-framework Accelerate")
    if(ENABLE_METAL)
        target_link_libraries(godot_llama PRIVATE "-framework Foundation" "-framework Metal" "-framework MetalKit")
    endif()
endif()

# Godot extension naming convention: godot-llama-cpp-triple-optimize
# For now, simple name; you can customize as needed
set_target_properties(godot_llama PROPERTIES
    OUTPUT_NAME godot_llama
)

# Install to addons directory
install(TARGETS godot_llama
        LIBRARY DESTINATION godot/addons/godot-llama-cpp/
        RUNTIME DESTINATION godot/addons/godot-llama-cpp/
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE)

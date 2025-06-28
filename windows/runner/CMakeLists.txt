cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply standard settings
apply_standard_settings(${BINARY_NAME})

# Define Flutter version macros
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that interfere with C++ standard library
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Link required libraries
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")

# Include directories
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run Flutter tool portions of the build
add_dependencies(${BINARY_NAME} flutter_assemble)

# 🔥 Firebase SDK Integration
set(FIREBASE_SDK_DIR "C:/Users/KARAN/firebase_cpp_sdk")

# Debugging: Print Firebase SDK path
message(STATUS "Using Firebase SDK from: ${FIREBASE_SDK_DIR}")

# Ensure Firebase includes are available
target_include_directories(${BINARY_NAME} PRIVATE
    "${FIREBASE_SDK_DIR}/include"
)

# Ensure correct library linking for Windows Release mode
set(CMAKE_BUILD_TYPE Release)

link_directories("${FIREBASE_SDK_DIR}/libs/windows/VS2019/MD/x64/Release")

target_link_libraries(${BINARY_NAME} PRIVATE
    "${FIREBASE_SDK_DIR}/libs/windows/VS2019/MD/x64/Release/firebase_firestore.lib"
)

# 🛠️ Suppress Debug Warnings (LNK4099)
target_link_options(${BINARY_NAME} PRIVATE "/ignore:4099")

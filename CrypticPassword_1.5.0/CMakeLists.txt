cmake_minimum_required(VERSION 3.20)
project(CrypticPasswordNative LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

enable_testing()

add_library(crypticpassword_core common/crypticpassword_core.c)
target_include_directories(crypticpassword_core PUBLIC common)

add_executable(crypticpassword_core_test tests/test_core.c)
target_link_libraries(crypticpassword_core_test PRIVATE crypticpassword_core)
add_test(NAME crypticpassword_core_test COMMAND crypticpassword_core_test)

if (WIN32)
    add_subdirectory(windows)
elseif (APPLE)
    add_subdirectory(mac)
elseif (UNIX)
    # Build the GTK+ app only when GTK+ development files are present.
    find_package(PkgConfig QUIET)
    if (PkgConfig_FOUND)
        pkg_check_modules(GTK3 QUIET gtk+-3.0)
        if (GTK3_FOUND)
            add_subdirectory(linux)
        else()
            message(STATUS "GTK+ 3 development files not found; skipping Linux GTK+ app target.")
        endif()
    endif()
endif()

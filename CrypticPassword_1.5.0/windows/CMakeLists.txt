cmake_minimum_required(VERSION 3.20)
project(CrypticPasswordWin32 LANGUAGES C RC)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_executable(CrypticPassword WIN32
    src/main_win32.c
    src/app.rc
    src/app.manifest
    ../common/crypticpassword_core.c
)

target_include_directories(CrypticPassword PRIVATE src ../common)
target_compile_definitions(CrypticPassword PRIVATE UNICODE _UNICODE)
target_link_libraries(CrypticPassword PRIVATE comctl32)

install(TARGETS CrypticPassword RUNTIME DESTINATION bin)

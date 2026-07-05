cmake_minimum_required(VERSION 3.20)
project(CrypticPasswordGTK LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)

add_executable(crypticpassword-gtk
    src/main_gtk.c
    ../common/crypticpassword_core.c
)

target_include_directories(crypticpassword-gtk PRIVATE ../common ${GTK3_INCLUDE_DIRS})
target_compile_options(crypticpassword-gtk PRIVATE ${GTK3_CFLAGS_OTHER} -Wall -Wextra)
target_link_libraries(crypticpassword-gtk PRIVATE ${GTK3_LIBRARIES})
target_link_directories(crypticpassword-gtk PRIVATE ${GTK3_LIBRARY_DIRS})

install(TARGETS crypticpassword-gtk RUNTIME DESTINATION bin)
install(FILES packaging/applications/org.cryptic.password.desktop DESTINATION share/applications)

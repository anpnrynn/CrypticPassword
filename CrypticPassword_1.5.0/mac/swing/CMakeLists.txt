cmake_minimum_required(VERSION 3.20)
project(CrypticPasswordSwing LANGUAGES NONE)

find_package(Java REQUIRED)

set(APP_NAME CrypticPassword)
set(CLASS_NAME CrypticPasswordSwing)
set(SRC ${CMAKE_CURRENT_SOURCE_DIR}/src/${CLASS_NAME}.java)
set(BUILD_CLASSES ${CMAKE_CURRENT_BINARY_DIR}/classes)
set(JAR_FILE ${CMAKE_CURRENT_BINARY_DIR}/${APP_NAME}.jar)
set(APP_DIR ${CMAKE_CURRENT_BINARY_DIR}/${APP_NAME}.app)
set(DMG_FILE ${CMAKE_CURRENT_BINARY_DIR}/${APP_NAME}-macos.dmg)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/package/CrypticPasswordLauncher.sh.in ${CMAKE_CURRENT_BINARY_DIR}/CrypticPasswordLauncher.sh @ONLY NEWLINE_STYLE UNIX)

add_custom_command(
    OUTPUT ${JAR_FILE}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${BUILD_CLASSES}
    COMMAND ${Java_JAVAC_EXECUTABLE} -Xlint:all -d ${BUILD_CLASSES} ${SRC}
    COMMAND ${CMAKE_COMMAND} -E echo "Main-Class: ${CLASS_NAME}" > ${CMAKE_CURRENT_BINARY_DIR}/MANIFEST.MF
    COMMAND ${Java_JAR_EXECUTABLE} cfm ${JAR_FILE} ${CMAKE_CURRENT_BINARY_DIR}/MANIFEST.MF -C ${BUILD_CLASSES} .
    DEPENDS ${SRC}
    VERBATIM)

add_custom_target(jar ALL DEPENDS ${JAR_FILE})

add_custom_target(app
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${APP_DIR}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${APP_DIR}/Contents/MacOS ${APP_DIR}/Contents/Resources/Java
    COMMAND ${CMAKE_COMMAND} -E copy ${JAR_FILE} ${APP_DIR}/Contents/Resources/Java/${APP_NAME}.jar
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/package/Info.plist ${APP_DIR}/Contents/Info.plist
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/CrypticPasswordLauncher.sh ${APP_DIR}/Contents/MacOS/${APP_NAME}
    COMMAND chmod +x ${APP_DIR}/Contents/MacOS/${APP_NAME}
    DEPENDS jar
    VERBATIM)

add_custom_target(dmg
    COMMAND hdiutil create -volname ${APP_NAME} -srcfolder ${APP_DIR} -ov -format UDZO ${DMG_FILE}
    DEPENDS app
    VERBATIM)

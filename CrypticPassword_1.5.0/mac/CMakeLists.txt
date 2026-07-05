cmake_minimum_required(VERSION 3.20)
project(CrypticPasswordSwift LANGUAGES Swift)

if (NOT APPLE)
    message(FATAL_ERROR "The CrypticPassword Swift/AppKit macOS app must be configured on macOS. Use mac/swing or the Swift core test on non-macOS hosts.")
endif()

set(CMAKE_Swift_LANGUAGE_VERSION 5)
set(APP_NAME CrypticPassword)
set(SWIFT_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/src/swift/CrypticPasswordApp.swift)

add_executable(${APP_NAME} MACOSX_BUNDLE ${SWIFT_SOURCE})
target_link_libraries(${APP_NAME} PRIVATE "-framework Cocoa")
set_target_properties(${APP_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/package/swift/Info.plist
    OUTPUT_NAME ${APP_NAME}
    XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "org.cryptic.password.swift"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
    XCODE_ATTRIBUTE_MACOSX_DEPLOYMENT_TARGET "10.13"
)

install(TARGETS ${APP_NAME} BUNDLE DESTINATION .)

set(CPACK_PACKAGE_NAME "CrypticPassword")
set(CPACK_PACKAGE_VENDOR "Anoop Kumar Narayanan")
set(CPACK_PACKAGE_VERSION "1.5.0")
set(CPACK_GENERATOR "DragNDrop")
set(CPACK_DMG_VOLUME_NAME "CrypticPassword")
include(CPack)

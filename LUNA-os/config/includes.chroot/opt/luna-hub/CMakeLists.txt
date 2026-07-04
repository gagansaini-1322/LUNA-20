# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2024 Luna OS Project
cmake_minimum_required(VERSION 3.20)
project(luna-hub VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

# Resources also paths
include(GNUInstallDirs)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Widgets)

qt_standard_project_setup(REQUIRES 6.5)

set(LUNA_HUB_CXX
    src/main.cpp
    src/controller/AppController.cpp
    src/controller/TelemetryController.cpp
    src/controller/PerformanceController.cpp
    src/controller/GameController.cpp
    src/controller/QueueController.cpp
    src/controller/SettingsController.cpp
    src/controller/NavigationController.cpp
    src/controller/NotificationController.cpp
    src/controller/FanController.cpp
    src/controller/SystemInfoController.cpp
    src/controller/LunaBoostController.cpp
    src/sysinfo/SysInfo.cpp
    src/sysinfo/GpuDetector.cpp
    src/bridge/IpcClient.cpp
    src/model/MockTelemetryModel.cpp
)

set(LUNA_HUB_HDR
    src/controller/AppController.h
    src/controller/TelemetryController.h
    src/controller/PerformanceController.h
    src/controller/GameController.h
    src/controller/QueueController.h
    src/controller/SettingsController.h
    src/controller/NavigationController.h
    src/controller/NotificationController.h
    src/controller/FanController.h
    src/controller/SystemInfoController.h
    src/controller/LunaBoostController.h
    src/sysinfo/SysInfo.h
    src/sysinfo/GpuDetector.h
    src/bridge/IpcClient.h
    src/model/MockTelemetryModel.h
)

qt_add_executable(luna-hub ${LUNA_HUB_CXX} ${LUNA_HUB_HDR})

target_include_directories(luna-hub PRIVATE src)

target_link_libraries(luna-hub PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

# Set QML module URI and expose qml dir for runtime
set(LUNA_HUB_QML_DIR ${CMAKE_CURRENT_SOURCE_DIR}/qml)
target_compile_definitions(luna-hub PRIVATE
    LUNA_HUB_QML_DIR="${LUNA_HUB_QML_DIR}"
    LUNA_HUB_VERSION="${PROJECT_VERSION}"
)

install(TARGETS luna-hub RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY qml DESTINATION ${CMAKE_INSTALL_DATADIR}/luna-hub)
install(DIRECTORY resources DESTINATION ${CMAKE_INSTALL_DATADIR}/luna-hub)

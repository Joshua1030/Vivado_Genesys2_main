# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "C:\\Vitus\\LTC2500_new\\LTC2500_new\\LTC2500_new\\LTC2500\\vitis_workspace\\ltc2500_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\sleep.h"
  "C:\\Vitus\\LTC2500_new\\LTC2500_new\\LTC2500_new\\LTC2500\\vitis_workspace\\ltc2500_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xiltimer.h"
  "C:\\Vitus\\LTC2500_new\\LTC2500_new\\LTC2500_new\\LTC2500\\vitis_workspace\\ltc2500_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xtimer_config.h"
  "C:\\Vitus\\LTC2500_new\\LTC2500_new\\LTC2500_new\\LTC2500\\vitis_workspace\\ltc2500_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\lib\\libxiltimer.a"
  )
endif()

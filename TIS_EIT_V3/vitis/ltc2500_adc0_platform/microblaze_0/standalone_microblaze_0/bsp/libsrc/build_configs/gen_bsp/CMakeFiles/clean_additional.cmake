# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "E:\\Vivado_Genesys2_main\\TIS_EIT_V3\\vitis\\ltc2500_adc0_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\sleep.h"
  "E:\\Vivado_Genesys2_main\\TIS_EIT_V3\\vitis\\ltc2500_adc0_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xiltimer.h"
  "E:\\Vivado_Genesys2_main\\TIS_EIT_V3\\vitis\\ltc2500_adc0_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xtimer_config.h"
  "E:\\Vivado_Genesys2_main\\TIS_EIT_V3\\vitis\\ltc2500_adc0_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\lib\\libxiltimer.a"
  )
endif()

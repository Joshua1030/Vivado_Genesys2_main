# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "E:\\Vivado_Genesys2_main\\NetronV2\\netronV2\\netronV2_Vitis_WS\\platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\sleep.h"
  "E:\\Vivado_Genesys2_main\\NetronV2\\netronV2\\netronV2_Vitis_WS\\platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xiltimer.h"
  "E:\\Vivado_Genesys2_main\\NetronV2\\netronV2\\netronV2_Vitis_WS\\platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xtimer_config.h"
  "E:\\Vivado_Genesys2_main\\NetronV2\\netronV2\\netronV2_Vitis_WS\\platform\\microblaze_0\\standalone_microblaze_0\\bsp\\lib\\libxiltimer.a"
  )
endif()

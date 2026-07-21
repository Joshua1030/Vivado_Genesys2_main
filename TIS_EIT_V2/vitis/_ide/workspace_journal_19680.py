# 2026-03-20T16:57:54.900040800
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.create_platform_component(name = "ltc2500_platform",hw_design = "$COMPONENT_LOCATION/../../ltc2500_bd_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

comp = client.create_app_component(name="ltc2500_read_v1",platform = "$COMPONENT_LOCATION/../ltc2500_platform/export/ltc2500_platform/ltc2500_platform.xpfm",domain = "standalone_microblaze_0")

platform = client.get_component(name="ltc2500_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

status = platform.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../ltc2500_top/ltc2500_bd_wrapper.xsa")

status = platform.build()

status = platform.build()

comp.build()


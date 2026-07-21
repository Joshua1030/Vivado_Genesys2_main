# 2026-04-17T16:21:32.095919200
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.create_platform_component(name = "ltc2500_adc0_platform",hw_design = "$COMPONENT_LOCATION/../../ltc2500_top/ltc2500_bd_wrapper_adc0.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

platform = client.get_component(name="ltc2500_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../ltc2500_top/ltc2500_bd_wrapper_apr_17.xsa")

status = platform.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()


# 2026-07-28T16:57:42.782667100
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../ltc2500_bd_wrapper.xsa")

status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

vitis.dispose()

vitis.dispose()


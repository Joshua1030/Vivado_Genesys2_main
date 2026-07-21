# 2026-03-27T14:42:33.977324500
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="ltc2500_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../ltc2500_top/ltc2500_bd_wrapper.xsa")

status = platform.build()

status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()


# 2026-08-07T17:31:12.926407600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../ltc2500_bd_wrapper.xsa")

status = platform.build()

vitis.dispose()


# 2026-06-11T17:17:41.649939500
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

platform = client.get_component(name="ltc2500_platform")
status = platform.build()

status = platform.build()

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()


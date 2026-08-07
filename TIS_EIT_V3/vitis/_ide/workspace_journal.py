# 2026-08-07T17:36:58.894701500
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()


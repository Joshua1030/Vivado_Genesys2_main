# 2026-07-20T23:16:20.300522400
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

vitis.dispose()


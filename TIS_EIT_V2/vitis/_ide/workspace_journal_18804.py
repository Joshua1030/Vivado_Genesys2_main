# 2026-07-08T14:22:33.153109900
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()


# 2026-08-07T17:02:49.367370300
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

comp.build()

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

comp.build()

platform = client.get_component(name="ltc2500_platform")
status = platform.build()

comp.build()

vitis.dispose()


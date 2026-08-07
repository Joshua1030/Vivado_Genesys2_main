# 2026-07-29T00:08:52.853587600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

status = platform.build()

comp.build()


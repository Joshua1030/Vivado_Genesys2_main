# 2026-07-14T17:22:22.763497500
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="ltc2500_adc0_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

status = platform.build()

comp.build()


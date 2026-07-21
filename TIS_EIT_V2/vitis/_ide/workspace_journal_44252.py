# 2026-03-20T18:51:36.229884600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="ltc2500_platform")
status = platform.build()

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()


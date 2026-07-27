# 2026-07-27T17:47:42.637031700
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

comp = client.get_component(name="ltc2500_read_v1")
comp.build()

vitis.dispose()


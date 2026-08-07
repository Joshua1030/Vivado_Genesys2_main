# 2026-08-07T17:33:39.759876800
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

# 2026-08-07T17:33:39.759876800
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

client.delete_component(name="ltc2500_platform")

comp = client.get_component(name="ltc2500_read_v1")
comp.build()


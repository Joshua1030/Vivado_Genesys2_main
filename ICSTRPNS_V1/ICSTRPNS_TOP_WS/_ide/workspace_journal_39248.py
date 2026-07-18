# 2026-06-02T13:57:25.924340900
import vitis

client = vitis.create_client()
client.set_workspace(path="ICSTRPNS_TOP_WS")

comp = client.get_component(name="ICSTRPNS_Control")
comp.build()

vitis.dispose()


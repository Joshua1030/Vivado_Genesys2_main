# 2026-06-18T12:03:14.796834100
import vitis

client = vitis.create_client()
client.set_workspace(path="ICSTRPNS_TOP_WS")

comp = client.get_component(name="ICSTRPNS_Control")
comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

vitis.dispose()


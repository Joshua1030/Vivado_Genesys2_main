# 2026-06-11T13:15:19.644440200
import vitis

client = vitis.create_client()
client.set_workspace(path="ICSTRPNS_TOP_WS")

comp = client.get_component(name="ICSTRPNS_Control")
comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

vitis.dispose()


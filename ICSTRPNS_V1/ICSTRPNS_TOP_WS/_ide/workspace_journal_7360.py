# 2026-06-08T18:31:32.477466300
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

vitis.dispose()


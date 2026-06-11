# 2026-06-10T16:09:01.307456700
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

comp.build()

vitis.dispose()

vitis.dispose()


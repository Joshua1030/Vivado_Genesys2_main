# 2026-05-29T14:59:39.430169100
import vitis

client = vitis.create_client()
client.set_workspace(path="ICSTRPNS_TOP_WS")

platform = client.get_component(name="platform")
status = platform.build()

status = platform.build()

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

comp.build()

comp.build()

vitis.dispose()


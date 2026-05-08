# 2025-12-12T15:07:01.706535
import vitis

client = vitis.create_client()
client.set_workspace(path="netronV2_Vitis_WS")

comp = client.get_component(name="netronV2_ctrl")
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


# 2025-12-04T02:51:42.937760200
import vitis

client = vitis.create_client()
client.set_workspace(path="netronV2_Vitis_WS")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.create_app_component(name="netronV2_ctrl",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="netronV2_ctrl")
comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

vitis.dispose()


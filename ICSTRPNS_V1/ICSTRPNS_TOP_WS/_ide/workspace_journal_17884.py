# 2026-05-12T16:05:00.639813200
import vitis

client = vitis.create_client()
client.set_workspace(path="ICSTRPNS_TOP_WS")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../ICSTRPNS_Top/ICSTRPNS_Top_V1/ICSTRPNS_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.create_app_component(name="hello_world",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0",template = "hello_world")

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../ICSTRPNS_Top/ICSTRPNS_Top_V1/design_1_wrapper.xsa")

client.delete_component(name="platform")

client.delete_component(name="platform")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../ICSTRPNS_Top/ICSTRPNS_Top_V1/design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

comp = client.create_app_component(name="ICSTRPNS_Control",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0",template = "hello_world")

comp = client.get_component(name="ICSTRPNS_Control")
comp.build()

status = platform.build()

comp.build()

comp.build()

comp.build()

vitis.dispose()


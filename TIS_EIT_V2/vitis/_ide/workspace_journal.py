# 2026-07-20T16:23:33.342113400
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.create_platform_component(name = "ltc2500_adc0_platform",hw_design = "$COMPONENT_LOCATION/../../ltc2500_bd_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

comp = client.create_app_component(name="LTC2500_component",platform = "$COMPONENT_LOCATION/../ltc2500_adc0_platform/export/ltc2500_adc0_platform/ltc2500_adc0_platform.xpfm",domain = "standalone_microblaze_0")

vitis.dispose()


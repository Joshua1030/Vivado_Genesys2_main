# ethernet_debug — ADC byte pacer + per-sample header

`ethernet_debug` sits between the LTC2500 driver and the UDP block. It reassembles each
32-bit ADC sample from `ltc_driver_fsm`'s byte stream, prepends a **2-byte header**
tagging the DAC (injection) and ADC (sense) channel of that sample, and re-emits the whole
thing byte-by-byte (paced by `clk_trg`) into `dist_mem_gen`/`UDP`.

- HDL: [`hdl/ethernet_debug_slave_lite_v1_0_S00_AXI.v`](hdl/ethernet_debug_slave_lite_v1_0_S00_AXI.v),
  [`hdl/ethernet_debug.v`](hdl/ethernet_debug.v).
- Base address: `0x44A60000` (registers unused by this logic).

## Wire format — 6 bytes per ADC sample

Each sample now emits **6 bytes** (was 4):

| Byte | Value | Meaning |
|:---:|:---:|---|
| 0 | `0xA5` | sync marker (`HDR_MARKER`) |
| 1 | `{0, DAC[2:0], 0, ADC[2:0]}` | channel tag: DAC channel in bits[6:4], ADC channel in bits[2:0] |
| 2 | `data[31:24]` | ADC sample MSB |
| 3 | `data[23:16]` | |
| 4 | `data[15:8]` | |
| 5 | `data[7:0]` | ADC sample LSB |

Channels are 0–7 (add 1 for CH1–CH8). The marker aids host resync, but can collide with
data bytes — rely on the fixed **6-byte stride**, not the marker alone.

### Host parser note
The stream changed from 4 to 6 bytes/sample. Any host-side UDP receiver **must** be updated:
read 6-byte records, split byte 1 into `dac = (b1>>4)&0x7`, `adc = b1 & 0x7`, and
reassemble the 32-bit sample from bytes 2–5 (big-endian).

## Inputs (BD)

| Signal | Wired to | Meaning |
|---|---|---|
| `o_eth_data[7:0]`, `o_eth_valid` | `ltc_driver_fsm` | incoming ADC sample bytes |
| `dac_ch[2:0]` | `IP_1/chanel_cnt` | DAC injection channel |
| `adc_ch[2:0]` | `IP_Three/adc_ch` | ADC sense channel |

`dac_ch`/`adc_ch` are latched together with the sample when its last byte arrives.

> **Coherency caveat:** `adc_ch` is captured when the sample finishes assembling; because
> of the mux→convert→read pipeline it may lead the sample's true channel by a step. If ILA
> shows an off-by-one channel tag, add a matching pipeline delay to `adc_ch` before the
> latch. Verify on hardware before trusting the tags.

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
| 1 | `{TIS, DAC[2:0], RUN, ADC[2:0]}` | tag byte — see below |
| 2 | `data[31:24]` | ADC sample MSB |
| 3 | `data[23:16]` | |
| 4 | `data[15:8]` | |
| 5 | `data[7:0]` | ADC sample LSB |

Tag byte (byte 1) bit by bit:

| Bit | Name | Meaning |
|:---:|---|---|
| 7 | `TIS` | TIS burst was active at this sample's aperture — separates **baseline** from **stimulation** samples |
| 6:4 | `DAC[2:0]` | injection pair, 0–7 |
| 3 | `RUN` | this sample belongs to a button-started measurement run |
| 2:0 | `ADC[2:0]` | sense channel, 0–7 |

Channels are 0–7 (add 1 for CH1–CH8). Bits 7 and 3 were previously always zero;
they now carry the TIS tags from [`IP_1`](../IP_1_1_0/README.md), latched at the
same MCLK rising edge as the channel numbers so the tag always describes the
instant the LTC2500 actually sampled.

The ADC free-runs continuously — it is **not** gated by TIS or by the run state.
Everything is streamed and the host segments it offline using these two bits.

### Host parser note
Read 6-byte records and split byte 1 as
`tis = (b1>>7)&1`, `dac = (b1>>4)&0x7`, `run = (b1>>3)&1`, `adc = b1 & 0x7`,
then reassemble the 32-bit sample from bytes 2–5 (big-endian).

**Do not frame on `0xA5`.** The payload bytes are arbitrary ADC data and could
always contain `0xA5`; and since bits 7/3 became tag bits the header byte is no
longer bounded by `0x77` either, so it can be `0xA5` too (`{TIS=1, DAC=2, RUN=0,
ADC=5}`). Sync once, then rely on the fixed **6-byte stride**.

## Inputs (BD)

| Signal | Wired to | Meaning |
|---|---|---|
| `o_eth_data[7:0]`, `o_eth_valid` | `ltc_driver_fsm` | incoming ADC sample bytes |
| `dac_ch[2:0]` | `IP_1/dac_ch_sel` | DAC injection pair |
| `adc_ch[2:0]` | `IP_Three/adc_ch` | ADC sense channel |
| `tis_on` | `IP_1/tis_on` | TIS burst active → tag byte bit 7 |
| `run_active` | `IP_1/run_active` | measurement run in progress → tag byte bit 3 |

`dac_ch`/`adc_ch` are latched together with the sample when its last byte arrives.

> **Coherency caveat:** `adc_ch` is captured when the sample finishes assembling; because
> of the mux→convert→read pipeline it may lead the sample's true channel by a step. If ILA
> shows an off-by-one channel tag, add a matching pipeline delay to `adc_ch` before the
> latch. Verify on hardware before trusting the tags.

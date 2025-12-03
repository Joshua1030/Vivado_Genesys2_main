#ifndef XPARAMETERS_H   /* prevent circular inclusions */
#define XPARAMETERS_H   /* by using protection macros */

/* Definitions for peripheral DECI_FILTER_0 */
#define XPAR_DECI_FILTER_0_BASEADDR 0x44a00000
#define XPAR_DECI_FILTER_0_HIGHADDR 0x44a0ffff

/* Definitions for peripheral DECI_FILTER_1 */
#define XPAR_DECI_FILTER_1_BASEADDR 0x44a10000
#define XPAR_DECI_FILTER_1_HIGHADDR 0x44a1ffff

/* Definitions for peripheral DECI_FILTER_2 */
#define XPAR_DECI_FILTER_2_BASEADDR 0x44a20000
#define XPAR_DECI_FILTER_2_HIGHADDR 0x44a2ffff

/* Definitions for peripheral DECI_FILTER_3 */
#define XPAR_DECI_FILTER_3_BASEADDR 0x44a30000
#define XPAR_DECI_FILTER_3_HIGHADDR 0x44a3ffff

/* Definitions for peripheral DECI_FILTER_4 */
#define XPAR_DECI_FILTER_4_BASEADDR 0x44a40000
#define XPAR_DECI_FILTER_4_HIGHADDR 0x44a4ffff

/*  BOARD definition */
#define XPS_BOARD_GENESYS2

#define XPAR_LMB_BRAM_0_BASEADDRESS 0x0
#define XPAR_LMB_BRAM_0_HIGHADDRESS 0x4000
#define XPAR_CPU_CORE_CLOCK_FREQ_HZ 100000000

#define XPAR_MICROBLAZE_ADDR_SIZE 32

/* Number of SLRs */
#define NUMBER_OF_SLRS 0x1

/* Device ID */
#define XPAR_DEVICE_ID "7k325t"

#endif  /* end of protection macro */
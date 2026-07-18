----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Jaimin Joshi
-- 
-- Create Date: 10/05/2017 01:32:32 PM
-- Design Name: 
-- Module Name: UDP_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Top level design for sending UDP packets out over the RGMII interface.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity UDP_top is
--  Port ( );
    Port ( clk100MHz : in    std_logic; -- system clock
           --switches  : in    std_logic_vector(3 downto 0);
           
           -- Control signals
           eth_int_b : in    std_logic; -- interrupt
           eth_pme_b : in    std_logic; -- power management event
           eth_rst_b : out   std_logic := '0'; -- reset
           -- Management interface
           eth_mdc       : out   std_logic := '0'; 
           eth_mdio      : inout std_logic := '0';
           -- Receive interface
           eth_rxck      : in    std_logic; 
           eth_rxctl     : in    std_logic;
           eth_rxd       : in    std_logic_vector(3 downto 0);
           -- Transmit interface
           eth_txck      : out   std_logic := '0';
           eth_txctl     : out   std_logic := '0';
           eth_txd       : out   std_logic_vector(3 downto 0)   := (others => '0');
           clk_125MHz    : in    std_logic;
           start_sending : in    std_logic;
           read_addr     : out   std_logic_vector (12 downto 0);
           outer_read_addr: in   std_logic_vector (1 downto 0);
           mem_out       : in    std_logic_vector (7  downto 0);
           clk_udp       : out   std_logic;
           mac_address   : in    std_logic_vector (47 downto 0)
    );
end UDP_top;

architecture Behavioral of UDP_top is
    signal max_count     : unsigned(26 downto 0)         := (others => '0');
    signal count         : unsigned(26 downto 0)         := (others => '0');
    --signal start_sending : std_logic                     := '0';
    signal reset_counter : unsigned(24 downto 0)         := (others => '0');
    signal debug         : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
    signal phy_ready     : std_logic                     := '0';
    signal tx_ready_meta : std_logic                     := '0';
    signal tx_ready      : std_logic                     := '0';
    signal ok_to_send    : std_logic                     := '0'; -- change to '1' for simulation
    signal user_data     : std_logic                     := '1';

    component byte_data is
        Port ( clk        : in STD_LOGIC;
               start      : in  STD_LOGIC;
               busy       : out STD_LOGIC;
               data       : out STD_LOGIC_VECTOR (7 downto 0);
               user_data  : out STD_LOGIC;
               data_valid : out STD_LOGIC;
               read_addr  : out STD_LOGIC_VECTOR (12 downto 0);
               outer_read_addr: in   STD_LOGIC_VECTOR (1 downto 0);
               mem_out    : in  STD_LOGIC_VECTOR (7 downto 0);
               mac_address: in  STD_LOGIC_VECTOR (47 downto 0)
               );
               
    end component;

    signal raw_byte1        : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal raw_byte2        : STD_LOGIC_VECTOR (7 downto 0) := x"FF";
    signal raw_byte_valid  : std_logic                     := '0';
    component add_crc32 is
        Port ( clk             : in  STD_LOGIC;
               data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
               data_enable_in  : in  STD_LOGIC;
               data_out        : out STD_LOGIC_VECTOR (7 downto 0);
               data_enable_out : out STD_LOGIC);
    end component;

    signal with_crc        : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal with_crc_valid  : std_logic                     := '0';
    
    component add_preamble is
        Port ( clk             : in  STD_LOGIC;
               data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
               data_enable_in  : in  STD_LOGIC;
               data_out        : out STD_LOGIC_VECTOR (7 downto 0);
               data_enable_out : out STD_LOGIC);
    end component;

    signal fully_framed        : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal fully_framed_valid  : std_logic                     := '0';

    signal dout                : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal doutctl             : STD_LOGIC := '0';
    ATTRIBUTE IOB : STRING ;
    ATTRIBUTE IOB OF dout    : signal IS "TRUE";
    ATTRIBUTE IOB OF doutctl : signal IS "TRUE";

    --------------------------------
    -- Clocking signals 
    -------------------------------- 
    signal clk50MHz    : std_logic;
    signal clk125MHz   : std_logic;
    signal clk125MHz90 : std_logic; -- for the TX clock
    signal clk25MHz    : std_logic;
    signal clkfb       : std_logic;
begin
   ---------------------------------------------------
   -- Strapping signals
   ----------------------------------------------------
   -- No pullups/pulldowns added
 
   ----------------------------------------------------
   -- Data for the packet packet 
   ----------------------------------------------------
clk_udp <= clk125MHz; 

data: byte_data port map ( 
      clk        => clk_125MHz,
      start      => start_sending,
      busy       => open,
      data       => raw_byte1,
      user_data  => user_data,
      Data_valid => raw_byte_valid,
      read_addr  => read_addr,
      outer_read_addr  => outer_read_addr,
      mem_out    => mem_out,
      mac_address=>mac_address
      );

i_add_crc32: add_crc32 port map (
      clk             => clk_125MHz,
      data_in         => raw_byte1,
      data_enable_in  => raw_byte_valid,
      data_out        => with_crc,
      data_enable_out => with_crc_valid);

i_add_preamble: add_preamble port map (
      clk             => clk_125MHz,
      data_in         => with_crc,
      data_enable_in  => with_crc_valid,
      data_out        => fully_framed,
      data_enable_out => fully_framed_valid);
      
   ----------------------------------------------------
   -- Send the data out to the ethernet PHY
   -- But only when it is OK to send after the
   -- PHY has been out of reset for long enough 
   ----------------------------------------------------
send_data_out: process(clk_125MHz)
    begin
       if falling_edge(clk_125MHz) then
           dout    <= fully_framed;
           doutctl <= fully_framed_valid and ok_to_send;
       end if;
    end process;

   ----------------------------------------------------
   -- DDR output registers 
   ----------------------------------------------------
tx_d0  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(0), C  => clk125MHz, CE => '1', R  => '0', S  => '0', D1 => dout(0), D2 => dout(4));
tx_d1  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(1), C  => clk125MHz, CE => '1', R  => '0', S  => '0', D1 => dout(1), D2 => dout(5));
tx_d2  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(2), C  => clk125MHz, CE => '1', R  => '0', S  => '0', D1 => dout(2), D2 => dout(6));
tx_d3  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(3), C  => clk125MHz, CE => '1', R  => '0', S  => '0', D1 => dout(3), D2 => dout(7));

-- The second bit of this should be tx_enable XOR tx_error, to be in line with the spec.
tx_ctl : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txctl,   C  => clk125MHz, CE => '1', R  => '0', S  => '0', D1 => doutctl, D2 => doutctl);

-- Note that this clock is shifted 90 degrees!
tx_c   : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txck,  C  => clk125MHz90, CE => '1', R  => '0', S  => '0', D1 => '1', D2 => '0');
    
monitor_reset_state: process(clk_125MHz)
    begin
       if rising_edge(clk_125MHz) then
          tx_ready      <= tx_ready_meta;
          tx_ready_meta <= phy_ready;
          if tx_ready = '1' and fully_framed_valid = '0' then
             ok_to_send    <= '1';
          end if;
       end if;
    end process;

    ----------------------------------------
    -- Control reseting the PHY
    ----------------------------------------
control_reset: process(clk_125MHz)
    begin
       if rising_edge(clk_125MHz) then           
          if reset_counter(reset_counter'high) = '0' then
              reset_counter <= reset_counter + 1;
          end if; 
           eth_rst_b <= reset_counter(reset_counter'high) or reset_counter(reset_counter'high-1);
          phy_ready  <= reset_counter(reset_counter'high);
       end if;
    end process;
    
   -------------------------------------------------------
   -- Generate a 25MHz and 50Mhz clocks from the 100MHz 
   -- system clock 
   ------------------------------------------------------- 
clocking : PLLE2_BASE
   generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLKFBOUT_MULT      => 10,
      CLKFBOUT_PHASE     => 0.0,
      CLKIN1_PERIOD      => 10.0,

      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT0_DIVIDE     => 8,  CLKOUT1_DIVIDE     => 20, CLKOUT2_DIVIDE      => 40, 
      CLKOUT3_DIVIDE     => 8,  CLKOUT4_DIVIDE     => 16, CLKOUT5_DIVIDE      => 16,

      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      CLKOUT0_DUTY_CYCLE => 0.5, CLKOUT1_DUTY_CYCLE => 0.5, CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5, CLKOUT4_DUTY_CYCLE => 0.5, CLKOUT5_DUTY_CYCLE => 0.5,

      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE      =>  0.0, CLKOUT1_PHASE      => 0.0, CLKOUT2_PHASE      => 0.0,
      CLKOUT3_PHASE      => 90.0, CLKOUT4_PHASE      => 0.0, CLKOUT5_PHASE      => 0.0,

      DIVCLK_DIVIDE      => 1,
      REF_JITTER1        => 0.0,
      STARTUP_WAIT       => "FALSE"
   )
   port map (
      CLKIN1   => CLK100MHz,
      CLKOUT0 => CLK125MHz,   CLKOUT1 => CLK50Mhz,  CLKOUT2 => CLK25MHz,  
      CLKOUT3 => CLK125MHz90, CLKOUT4 => open,      CLKOUT5 => open,
      LOCKED   => open,
      PWRDWN   => '0', 
      RST      => '0',
      CLKFBOUT => clkfb,
      CLKFBIN  => clkfb
   );
end Behavioral;

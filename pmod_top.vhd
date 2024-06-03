LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY pmod IS
 
  PORT(
    clk             : IN     STD_LOGIC;                     --system clock
    reset_n         : IN     STD_LOGIC;                     --active low reset
    miso            : IN     STD_LOGIC;                     --SPI master in, slave out
    mosi            : OUT    STD_LOGIC;                     --SPI master out, slave in
    sclk            : BUFFER STD_LOGIC;                     --SPI clock
    cs_n            : OUT    STD_LOGIC;                     --pmod chip select
    trigger_button  : OUT    STD_LOGIC;                     --trigger button status
    center_button   : OUT    STD_LOGIC);                    --center button status
END pmod;

architecture wahab of pmod is 

-- component decalaration
component pmod_joystick IS
  GENERIC(
    clk_freq        : INTEGER := 50); --system clock frequency in MHz
  PORT(
    clk             : IN     STD_LOGIC;                     --system clock
    reset_n         : IN     STD_LOGIC;                     --active low reset
    miso            : IN     STD_LOGIC;                     --SPI master in, slave out
    mosi            : OUT    STD_LOGIC;                     --SPI master out, slave in
    sclk            : BUFFER STD_LOGIC;                     --SPI clock
    cs_n            : OUT    STD_LOGIC;                     --pmod chip select
    x_position      : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);  --joystick x-axis position
    y_position      : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);  --joystick y-axis position
    trigger_button  : OUT    STD_LOGIC;                     --trigger button status
    center_button   : OUT    STD_LOGIC);                    --center button status
END component;

     signal x_position      :    STD_LOGIC_VECTOR(7 DOWNTO 0);  --joystick x-axis position
    signal y_position      :     STD_LOGIC_VECTOR(7 DOWNTO 0);  --joystick y-axis position
begin
joystick: pmod_joystick 
generic map (clk_freq => 50)
port map(
clk =>clk,
reset_n => reset_n,
miso => miso,
mosi => mosi,
sclk => sclk,
cs_n => cs_n,
x_position => x_position,
y_position => y_position,
trigger_button => trigger_button,
center_button => center_button

);



end wahab;
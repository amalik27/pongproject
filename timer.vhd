library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all; -- For arithmetic operations

entity timer is
    Port ( 
        clk         : in STD_LOGIC;
        reset       : in STD_LOGIC;
        timer_start : in STD_LOGIC;
        timer_tick  : in STD_LOGIC;
        timer_up    : out STD_LOGIC
    );
end timer;

architecture Behavioral of timer is
    -- Signal declaration
    signal timer_reg : std_logic_vector(7 downto 0) := (others => '1'); -- 7'b1111111
    signal timer_next: std_logic_vector(7 downto 0);
begin
    -- Register control
    process(clk, reset)
    begin
        if reset = '1' then
            timer_reg <= (others => '1'); -- Reset to all 1's
        elsif rising_edge(clk) then
            timer_reg <= timer_next;
        end if;
    end process;

    -- Next state logic
    timer_next_logic: process(timer_start, timer_tick, timer_reg)
    begin
        if timer_start = '1' then
            timer_next <= (others => '1'); -- Set to all 1's
        elsif timer_tick = '1' and timer_reg /= 0 then
            timer_next <= timer_reg - 1; -- Decrement
        else
            timer_next <= timer_reg; -- Hold
        end if;
    end process;

    -- Output
    timer_up <= '1' when timer_reg = 0 else '0';

end Behavioral;
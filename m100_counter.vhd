library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all; -- For arithmetic operations on unsigned types

entity m100_counter is
    Port ( 
        clk    : in STD_LOGIC;
        reset  : in STD_LOGIC;
        d_inc  : in STD_LOGIC; -- Increment signal for Player 1
        d_inc2 : in STD_LOGIC; -- Increment signal for Player 2
        d_clr  : in STD_LOGIC; -- Clear signal
        dig0   : out STD_LOGIC_VECTOR(3 downto 0); -- Score for Player 1
        dig1   : out STD_LOGIC_VECTOR(3 downto 0)  -- Score for Player 2
    );
end m100_counter;


architecture Behavioral of m100_counter is
    -- Internal signals for holding the next state of the digits
    signal r_dig0, r_dig1, dig0_next, dig1_next: std_logic_vector(3 downto 0) := (others => '0');
begin
    -- Process for register control and next state logic
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset digits to 0
            r_dig1 <= (others => '0');
            r_dig0 <= (others => '0');
        elsif rising_edge(clk) then
            -- Load the next state into the registers
            r_dig1 <= dig1_next;
            r_dig0 <= dig0_next;
        end if;
    end process;

    -- Process for next state logic
    process(d_inc, d_inc2, d_clr, r_dig0, r_dig1)
    begin
        -- By default, maintain the current state
        dig0_next <= r_dig0;
        dig1_next <= r_dig1;

        -- Clear condition
        if d_clr = '1' then
            dig0_next <= (others => '0');
            dig1_next <= (others => '0');
        else
            -- Increment logic for Player 1
            if d_inc = '1' then
                if r_dig0 = "1001" then -- Equivalent to decimal 9
                    dig0_next <= (others => '0');
                else
                    dig0_next <= ((r_dig0) + 1);
                end if;
            end if;
            
            -- Increment logic for Player 2
            if d_inc2 = '1' then
                if r_dig1 = "1001" then -- Equivalent to decimal 9
                    dig1_next <= (others => '0');
                else
                    dig1_next <= ((r_dig1) + 1);
                end if;
            end if;
        end if;
    end process;

    -- Output assignments
    dig0 <= (r_dig0);
    dig1 <= (r_dig1);
end Behavioral;


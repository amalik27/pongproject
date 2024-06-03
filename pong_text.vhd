library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all;

entity pong_text is
    Port (
        clk  , player_wins    : in STD_LOGIC;
        ball     : in STD_LOGIC_VECTOR(2 downto 0);
        dig0     : in STD_LOGIC_VECTOR(3 downto 0);
        game_mode : in std_logic;
        dig1     : in STD_LOGIC_VECTOR(3 downto 0);
        x        : in STD_LOGIC_VECTOR(9 downto 0);
        y        : in STD_LOGIC_VECTOR(9 downto 0);
        text_on  : out STD_LOGIC_VECTOR(3 downto 0);
        text_rgb : out STD_LOGIC_VECTOR(15 downto 0)
    );
end pong_text;

architecture Behavioral of pong_text is
    -- Signal declaration
    signal rom_addr       : STD_LOGIC_VECTOR(10 downto 0);
    signal char_addr      : STD_LOGIC_VECTOR(6 downto 0);
    signal char_addr_s    : STD_LOGIC_VECTOR(6 downto 0);
    signal char_addr_l    : STD_LOGIC_VECTOR(6 downto 0);
    signal char_addr_r    : STD_LOGIC_VECTOR(6 downto 0);
    signal char_addr_o    : STD_LOGIC_VECTOR(6 downto 0);
    signal row_addr       : STD_LOGIC_VECTOR(3 downto 0);
    signal row_addr_s     : STD_LOGIC_VECTOR(3 downto 0);
    signal row_addr_l     : STD_LOGIC_VECTOR(3 downto 0);
    signal row_addr_r     : STD_LOGIC_VECTOR(3 downto 0);
    signal row_addr_o     : STD_LOGIC_VECTOR(3 downto 0);
    signal bit_addr   ,not_bit_addr    : STD_LOGIC_VECTOR(2 downto 0);
    signal bit_addr_s     : STD_LOGIC_VECTOR(2 downto 0);
    signal bit_addr_l     : STD_LOGIC_VECTOR(2 downto 0);
    signal bit_addr_r     : STD_LOGIC_VECTOR(2 downto 0);
    signal bit_addr_o     : STD_LOGIC_VECTOR(2 downto 0);
    signal ascii_word     : STD_LOGIC_VECTOR(7 downto 0);
    signal ascii_bit      : STD_LOGIC;
    signal score_on       : STD_LOGIC;
    signal logo_on        : STD_LOGIC;
    signal rule_on        : STD_LOGIC;
    signal over_on        : STD_LOGIC;
    signal rule_rom_addr  : STD_LOGIC_VECTOR(7 downto 0);
    component ascii_rom port 
    (
    clk : in std_logic;
    addr : in std_logic_vector(10 downto 0);
    data : out std_logic_vector(7 downto 0)
    
    ); end component;
begin
    
    ascii_unit : ascii_rom port map (clk=> clk, addr=>rom_addr, data=>ascii_word);
    
    -- Score region logic
score_on <= '1' when ((y) >= 32) and ((y) < 64) and (((x(9 downto 4))) < 16) else '0';
row_addr_s <= y(4 downto 1);
bit_addr_s <= x(3 downto 1);


-- Character address selection logic
process(x, dig1, dig0, ball)
begin
    case x(7 downto 4) is
        when "0000" =>
            char_addr_s <= "1010011"; -- S
        when "0001" =>
            char_addr_s <= "1000011"; -- C
        when "0010" =>
            char_addr_s <= "1001111"; -- O
        when "0011" =>
            char_addr_s <= "1010010"; -- R
        when "0100" =>
            char_addr_s <= "1000101"; -- E
        when "0101" =>
            char_addr_s <= "0111010"; -- :
        when "0110" =>
            char_addr_s <= "011" & dig1; -- tens digit
        when "0111" =>
            char_addr_s <= "010" & x"D"; -- -
        when "1000" =>
            char_addr_s <= "011" & dig0; -- ones digit
        when "1001" =>
            char_addr_s <= (others => '0'); -- space
        when "1010" =>
            char_addr_s <= "1000010"; -- B
        when "1011" =>
            char_addr_s <= "1000001"; -- A
        when "1100" =>
            char_addr_s <= "1001100"; -- L
        when "1101" =>
            char_addr_s <= "1001100"; -- L
        when "1110" =>
            char_addr_s <= "0111010"; -- :
        when others =>
            char_addr_s <= "0110" & ball; -- assuming 'ball' is already a binary encoded STD_LOGIC_VECTOR
    end case;
end process;

    -- Logo region
    logo_on <= '1' when y(9 downto 7) = "010" and 
                        x(9 downto 6) >= "0011" and 
                        x(9 downto 6) <= "0110" else '0';
    row_addr_l <= y(6 downto 3);
    bit_addr_l <= x(5 downto 3);

     -- Logo character address selection logic
    Logo_Char_Selection: process(x)
    begin
        case x(8 downto 6) is
            when "011" => 
                char_addr_l <= "1010000"; -- P
            when "100" => 
                char_addr_l <= "1001111"; -- O
            when "101" => 
                char_addr_l <= "1001110"; -- N
            when others => 
                char_addr_l <= "1000111"; -- G
        end case;
    end process Logo_Char_Selection;
    
    -- Rule region
    rule_on <= '1' when x(9 downto 7) = "010" and y(9 downto 6) = "0010" else '0';
    row_addr_r <= y(3 downto 0);
    bit_addr_r <= x(2 downto 0);
    rule_rom_addr(5 downto 0) <=   y(5 downto 4) & x(6 downto 3);
    
    -- Rules text character address selection logic
    Rule_Char_Selection: process(rule_rom_addr)
    begin
        case rule_rom_addr(5 downto 0) is
            -- row 1
            when "000000" => char_addr_r <= "1010010"; -- R
            when "000001" => char_addr_r <= "1010101"; -- U
            when "000010" => char_addr_r <= "1001100"; --L
            when "000011" => char_addr_r <= "1000101"; --E
            when "000100" => char_addr_r <= "0111010"; --
            when "000101" => char_addr_r <= "0000000"; --
            when "000110" => char_addr_r <= "0000000"; --
            when "000111" => char_addr_r <= "0000000"; --
            when "001000" => char_addr_r <= "0000000"; --
            when "001001" => char_addr_r <= "0000000"; --
            when "001010" => char_addr_r <= "0000000"; --
            when "001011" => char_addr_r <= "0000000"; --
            when "001100" => char_addr_r <= "0000000"; --
            when "001101" => char_addr_r <= "0000000"; --
            when "001110" => char_addr_r <= "0000000"; --
            when "001111" => char_addr_r <= "0000000"; --
            
            --row 2
            when "010000" => char_addr_r <= "1010101"; -- U
            when "010001" => char_addr_r <= "1010011"; -- S
            when "010010" => char_addr_r <= "1000101"; --E
            when "010011" => char_addr_r <= "0000000"; --
            when "010100" => char_addr_r <= "1010100"; --T
            when "010101" => char_addr_r <= "1010111"; --W
            when "010110" => char_addr_r <= "1001111"; --O
            when "010111" => char_addr_r <= "0000000"; --
            when "011000" => char_addr_r <= "1000010"; --B
            when "011001" => char_addr_r <= "1010101"; --U
            when "011010" => char_addr_r <= "1010100"; --T
            when "011011" => char_addr_r <= "1010100"; --T
            when "011100" => char_addr_r <= "1001111"; --O
            when "011101" => char_addr_r <= "1001110"; --N
            when "011110" => char_addr_r <= "1010011"; --S
            when "011111" => char_addr_r <= "0000000"; --
            
            --row 3
            when "100000" => char_addr_r <= "1010100"; -- T
            when "100001" => char_addr_r <= "1001111"; -- O
            when "100010" => char_addr_r <= "0000000"; --
            when "100011" => char_addr_r <= "1001101"; --M
            when "100100" => char_addr_r <= "1001111"; --O
            when "100101" => char_addr_r <= "1010110"; --V
            when "100110" => char_addr_r <= "1000101"; --E
            when "100111" => char_addr_r <= "0000000"; --
            when "101000" => char_addr_r <= "1010000"; --P
            when "101001" => char_addr_r <= "1000001"; --A
            when "101010" => char_addr_r <= "1000100"; --D
            when "101011" => char_addr_r <= "1000100"; --D
            when "101100" => char_addr_r <= "1001100"; --L
            when "101101" => char_addr_r <= "1000101"; --E
            when "101110" => char_addr_r <= "0000000"; --
            when "101111" => char_addr_r <= "0000000"; --
            
            -- row 4
            when "110000" => char_addr_r <= "1010101"; -- U
            when "110001" => char_addr_r <= "1010000"; -- P
            when "110010" => char_addr_r <= "0000000"; --
            when "110011" => char_addr_r <= "1000001"; --A
            when "110100" => char_addr_r <= "1001110"; --N
            when "110101" => char_addr_r <= "1000100"; --D
            when "110110" => char_addr_r <= "0000000"; --
            when "110111" => char_addr_r <= "1000100"; --D
            when "111000" => char_addr_r <= "1001111"; --O
            when "111001" => char_addr_r <= "1010111"; --W
            when "111010" => char_addr_r <= "1001110"; --N
            when "111011" => char_addr_r <= "0000000"; --
            when "111100" => char_addr_r <= "0000000"; --
            when "111101" => char_addr_r <= "0000000"; --
            when "111110" => char_addr_r <= "0000000"; --
            when "111111" => char_addr_r <= "0000000"; --
            end case;
    end process Rule_Char_Selection;
    
    -- Game over region
    over_on <= '1' when y(9 downto 6) = x"3" and 
                        x(9 downto 5) >= "00000" and 
                        x(9 downto 5) <= "10100" else '0';
    row_addr_o <= y(5 downto 2);
    bit_addr_o <= x(4 downto 2);

    -- Game over character address selection logic
Game_Over_Char_Selection : process(x,player_wins)
begin
    case x(9 downto 5) is
        when "00000" => 
            char_addr_o <= "1000111"; -- Binary for ASCII 'G'
        when "00001" => 
            char_addr_o <= "1000001"; -- Binary for ASCII 'A'
        when "00010" => 
            char_addr_o <= "1001101"; -- Binary for ASCII 'M'
        when "00011" => 
            char_addr_o <= "1000101"; -- Binary for ASCII 'E'
        when "00100" => 
            char_addr_o <= "1001111"; -- Binary for ASCII 'O'
        when "00101" => 
            char_addr_o <= "1010110"; -- Binary for ASCII 'V'
        when "00110" => 
            char_addr_o <= "1000101"; -- Binary for ASCII 'E'
        when "00111" => 
            char_addr_o <= "1010010"; -- Binary for ASCII 'R' 
        when "01000" => 
            char_addr_o <= "0000000"; -- Binary for ASCII Space (assuming space is represented as 0)
        when "01001" => 
            char_addr_o <= "1010000"; --Binary for ASCII 'P'
        when "01010" =>
            char_addr_o <= "1001100"; --Binary for ASCII 'L'
        when "01011" =>
            char_addr_o <= "1000001"; --Binary for ASCII 'A'
        when "01100" =>
            char_addr_o <= "1011001"; --Binary for ASCII 'Y'
        when "01101" =>
            char_addr_o <= "1000101"; --Binary for ASCII 'E'
        when "01110" =>
        if player_wins = '1' then
            char_addr_o <= "0110001"; --Binary for ASCII '1'
        elsif player_wins = '0' then 
            char_addr_o <= "0110010"; --Binary for ASCII '2'
        end if;
        when "01111" =>
            char_addr_o <= "0000000"; --Binary for ASCII 'P'
        when "10000" =>
            char_addr_o <= "1010111"; --Binary for ASCII 'W'
        when "10001" =>
            char_addr_o <= "1001001"; --Binary for ASCII 'I'
        when "10010" =>
            char_addr_o <= "1001110"; --Binary for ASCII 'N'
        when "10011" =>
            char_addr_o <= "1010011"; --Binary for ASCII 'S'
        when others =>
            char_addr_o <= "1010011"; --Binary for ASCII 'S'
        
    end case;
end process Game_Over_Char_Selection;

    
    -- Text RGB and ROM address generation logic
    Mux_Process: process(char_addr,char_addr_s,row_addr)
    begin
        if(game_mode = '1' ) then 
            text_rgb <= "0000011111111111"; -- aqua background
        else
            text_rgb <= "1111100011100111";
        
        end if;

        if score_on = '1' then
            char_addr <= char_addr_s;
            row_addr <= row_addr_s;
            bit_addr <= bit_addr_s;
            if ascii_bit = '1' then
                text_rgb <= "1111100000000000"; -- red
            end if;
        elsif rule_on = '1' then
            char_addr <= char_addr_r;
            row_addr <= row_addr_r;
            bit_addr <= bit_addr_r;
            if ascii_bit = '1' then
                text_rgb <= "1111100000000000"; -- red
            end if;
        elsif logo_on = '1' then
            char_addr <= char_addr_l;
            row_addr <= row_addr_l;
            bit_addr <= bit_addr_l;
            if ascii_bit = '1' then
                text_rgb <= "1111100000000000"; -- yellow
            end if;
        else
            char_addr <= char_addr_o;
            row_addr <= row_addr_o;
            bit_addr <= bit_addr_o;
            if ascii_bit = '1' then
                text_rgb <= "1111100000000000"; -- red
            end if;
        end if;
    end process Mux_Process;

    -- Text on signal assignment
    text_on <= score_on & logo_on & rule_on & over_on;

    -- ROM address calculation
    rom_addr <= char_addr & row_addr;
    not_bit_addr <= not bit_addr;

    process(not_bit_addr, bit_addr)
begin
    case not_bit_addr is
        when "000" =>
            ascii_bit <= ascii_word(0); -- First bit for column 0
        when "001" =>
            ascii_bit <= ascii_word(1); -- Second bit for column 1
        when "010" =>
            ascii_bit <= ascii_word(2); -- Third bit for column 2
        when "011" =>
            ascii_bit <= ascii_word(3); -- Fourth bit for column 3
        when "100" =>
            ascii_bit <= ascii_word(4); -- Fifth bit for column 4
        when "101" =>
            ascii_bit <= ascii_word(5); -- Sixth bit for column 5
        when "110" =>
            ascii_bit <= ascii_word(6); -- Seventh bit for column 6
        when "111" =>
            ascii_bit <= ascii_word(7); -- Eighth bit for column 7
        when others =>
            ascii_bit <= '0'; -- Default case, not strictly necessary unless undefined behavior is possible
    end case;
end process;
            
end Behavioral;

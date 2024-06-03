library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all; -- Library for arithmetic operations on std_logic_vector.

entity pong_graph is
    Port (
        clk        : in STD_LOGIC;
        reset      : in STD_LOGIC;
        btn        : in STD_LOGIC_VECTOR(1 downto 0); -- btn(0) = up, btn(1) = down for Player One
        btn2       : in STD_LOGIC_VECTOR(1 downto 0); -- btn2(0) = up, btn2(1) = down for Player Two
        gra_still  : in STD_LOGIC;                    -- Still graphics
        sensitivity : in std_logic_vector(1 downto 0);
        game_pause : in STD_LOGIC;                    -- Pause input
        video_on   : in STD_LOGIC;
        x          : in STD_LOGIC_VECTOR(9 downto 0);
        y          : in STD_LOGIC_VECTOR(9 downto 0);
        background      : in std_logic;
        graph_on   : out STD_LOGIC;
        hit        : out STD_LOGIC;                    -- Ball hit
        miss1, miss2       : out STD_LOGIC;                    -- Ball miss
        graph_rgb  : out STD_LOGIC_VECTOR(15 downto 0) -- RGB graphics output
    );
end pong_graph;

architecture Behavioral of pong_graph is
    -- Maximum x, y values in display area
    constant X_MAX : integer := 639;
    constant Y_MAX : integer := 479;

    -- Create 60Hz refresh tick
    signal refresh_tick : STD_LOGIC;

    -- WALLS
    -- LEFT wall boundaries
    constant L_WALL_L : integer := 0;
    constant L_WALL_R : integer := 09; -- 8 pixels wide
    -- TOP wall boundaries
    constant T_WALL_T : integer := 64;
    constant T_WALL_B : integer := 71; -- 8 pixels wide
    -- BOTTOM wall boundaries
    constant B_WALL_T : integer := 472;
    constant B_WALL_B : integer := 479;-- 8 pixels wide

    -- PADDLE
    -- Paddle horizontal boundaries
    constant X_PAD_L : integer := 622;
    constant X_PAD_R : integer := 625; -- 4 pixels wide
    -- Paddle vertical boundary signals
    signal y_pad_t : STD_LOGIC_VECTOR(9 downto 0);
    signal y_pad_b : STD_LOGIC_VECTOR(9 downto 0);
    constant PAD_HEIGHT : integer := 72; -- 72 pixels high
    -- Register to track top boundary and buffer
    signal y_pad_reg : STD_LOGIC_VECTOR(9 downto 0) := "0011001100"; -- Paddle starting position
    signal y_pad_next : STD_LOGIC_VECTOR(9 downto 0);
    -- Paddle moving velocity when a button is pressed
    signal PAD_VELOCITY : integer ; -- Change to speed up or slow down paddle movement

    -- Paddle 2 (Player Two) parameters and initial position
    constant X_PAD2_L : integer := 25; -- Position Player Two's paddle on the right side of the screen
    constant X_PAD2_R : integer := 28; -- Ensure it's 4 pixels wide
    constant PAD2_COLOR : STD_LOGIC_VECTOR(15 downto 0) := "0000011111100000"; -- Green color for Player Two's paddle

    -- Paddle 2 vertical position and movement control
    signal y_pad2_reg : STD_LOGIC_VECTOR(9 downto 0) := "0000011001"; -- Initial position
    signal y_pad2_t : STD_LOGIC_VECTOR(9 downto 0);
    signal y_pad2_b : STD_LOGIC_VECTOR(9 downto 0);
    signal y_pad2_next : STD_LOGIC_VECTOR(9 downto 0);

    -- BALL
    -- Square ROM boundaries
    constant BALL_SIZE : integer := 8;
    -- Ball horizontal boundary signals
    signal x_ball_l : STD_LOGIC_VECTOR(9 downto 0);
    signal x_ball_r : STD_LOGIC_VECTOR(9 downto 0);
    -- Ball vertical boundary signals
    signal y_ball_t : STD_LOGIC_VECTOR(9 downto 0);
    signal y_ball_b : STD_LOGIC_VECTOR(9 downto 0);
    -- Register to track top left position
    signal y_ball_reg : STD_LOGIC_VECTOR(9 downto 0);
    signal x_ball_reg : STD_LOGIC_VECTOR(9 downto 0);
    -- Signals for register buffer
    signal y_ball_next : STD_LOGIC_VECTOR(9 downto 0);
    signal x_ball_next : STD_LOGIC_VECTOR(9 downto 0);
    -- Registers to track ball speed and buffers
    signal x_delta_reg : STD_LOGIC_VECTOR(9 downto 0);
    signal x_delta_next : STD_LOGIC_VECTOR(9 downto 0);
    signal y_delta_reg : STD_LOGIC_VECTOR(9 downto 0);
    signal y_delta_next : STD_LOGIC_VECTOR(9 downto 0);
    -- Positive or negative ball velocity
    signal BALL_VELOCITY_POS : STD_LOGIC_VECTOR(9 downto 0) ; -- Ball speed positive pixel direction (down, right)
    signal BALL_VELOCITY_NEG : STD_LOGIC_VECTOR(9 downto 0) ; -- Ball speed negative pixel direction (up, left)
    -- Round ball from square image
    signal rom_addr : STD_LOGIC_VECTOR(2 downto 0);
    signal rom_col : STD_LOGIC_VECTOR(2 downto 0); -- 3-bit ROM address and ROM column
    signal rom_data : STD_LOGIC_VECTOR(7 downto 0); -- Data at current ROM address
    signal rom_bit : STD_LOGIC; -- Signify when ROM data is 1 or 0 for ball RGB control

    -- OBJECT STATUS SIGNALS
    signal l_wall_on, t_wall_on, b_wall_on, pad_on, pad2_on, sq_ball_on, ball_on : STD_LOGIC;
    signal wall_rgb, pad_rgb, ball_rgb, bg_rgb : STD_LOGIC_VECTOR(15 downto 0);
begin
-- for ball and paddles sensitivity
process(clk,sensitivity)
begin
    case sensitivity is 
    
    when "00" =>  -- easy mode
        PAD_VELOCITY <= 3;
        BALL_VELOCITY_POS <= "0000000001"; -- 2
        BALL_VELOCITY_NEG <= "1111111110"; -- -2
    
    when "01" =>  -- medium mode
        PAD_VELOCITY <= 4;
        BALL_VELOCITY_POS <= "0000000010"; -- 3
        BALL_VELOCITY_NEG <= "1111111101"; -- -3
    
    when "10" =>  -- difficult mode
        PAD_VELOCITY <= 5;
        BALL_VELOCITY_POS <= "0000000011"; -- 4
        BALL_VELOCITY_NEG <= "1111111100"; -- -4
    
    when "11" =>  -- impossible mode
        PAD_VELOCITY <= 8;
        BALL_VELOCITY_POS <= "0000000100"; -- 5
        BALL_VELOCITY_NEG <= "1111111011"; -- -5
    
    
    end case;


end process;


refresh_tick <= '1' when ((y = 481) and (x = 0)) else '0';
    process(clk, reset)
begin

    if reset = '1' then
        y_pad_reg <= "0011001100";
        y_pad2_reg <= "0000011001";
        x_ball_reg <= (others => '0');
        y_ball_reg <= (others => '0');
        x_delta_reg <= "0000000010"; 
        y_delta_reg <= "0000000010";
    elsif rising_edge(clk) then
        y_pad_reg <= y_pad_next;
        y_pad2_reg <= y_pad2_next;
        x_ball_reg <= x_ball_next;
        y_ball_reg <= y_ball_next;
        x_delta_reg <= x_delta_next;
        y_delta_reg <= y_delta_next;
    end if;
end process;

    process(rom_addr)
begin
    case rom_addr is
        when "000" =>
            rom_data <= "00111100"; --   ****
        when "001" =>
            rom_data <= "01111110"; --  ******
        when "010" =>
            rom_data <= "11111111"; -- ********
        when "011" =>
            rom_data <= "11111111"; -- ********
        when "100" =>
            rom_data <= "11111111"; -- ********
        when "101" =>
            rom_data <= "11111111"; -- ********
        when "110" =>
            rom_data <= "01111110"; --  ******
        when "111" =>
            rom_data <= "00111100"; --   ****
        when others =>
            rom_data <= (others => '0');
    end case;
end process;
--pixel within wall boundaries
l_wall_on <= '1' when (x) >= L_WALL_L and (x) <= L_WALL_R else '0';
t_wall_on <= '1' when (y) >= T_WALL_T and (y) <= T_WALL_B else '0';
b_wall_on <= '1' when (y) >= B_WALL_T and (y) <= B_WALL_B else '0';


process (background)
begin
if(background = '1') then
bg_rgb <= "0000011111100000";
wall_rgb <= "0000000000011111"; -- blue walls
pad_rgb <= "0000000000011111";  -- blue paddle
ball_rgb <= "1111100000000000"; -- red ball

else 
bg_rgb <= "1111100000011111";
wall_rgb <= "0000000000011110"; -- 
pad_rgb <= "0000000000011110";  -- 
ball_rgb <= "1111000000000000"; -- 
end if;

end process;

    -- Paddle position calculations
y_pad_t <= y_pad_reg; -- Paddle top position correctly assigned
-- Correctly calculate and assign the paddle bottom position
y_pad_b <= (y_pad_reg) + (PAD_HEIGHT) - 1; -- Subtracting 1 is unnecessary since we're directly calculating the bottom position

-- For paddle 2, the top position is already assigned, let's correct the bottom position calculation
--y_pad2_b <= (y_pad2_reg) + (PAD_HEIGHT) - 1;

-- Correct the conditional assignments for 'pad_on' and 'pad2_on'
pad_on <= '1' when (X_PAD_L <= x) and (x <= X_PAD_R) and
                      (y_pad_t <= y) and (y <= y_pad_b) else '0';

pad2_on <= '1' when (X_PAD2_L <= x) and (x <= X_PAD2_R) and
                       (y_pad2_t <= y) and (y <= y_pad2_b) else '0';

-- Paddle Control for Paddle 1
Paddle_Control: process(clk, btn)
begin
    if rising_edge(clk) then
        if refresh_tick = '1' then
            -- Move paddle 1 down, ensuring it doesn't go beyond the bottom wall boundary
            if (btn(1) = '1' and (y_pad_b < (B_WALL_T - 1 - PAD_VELOCITY))) then
                y_pad_next <= y_pad_reg + PAD_VELOCITY;
            -- Move paddle 1 up, ensuring it doesn't go beyond the top wall boundary
            elsif (btn(0) = '1' and (y_pad_t > (T_WALL_B - 1 - PAD_VELOCITY))) then
                y_pad_next <= y_pad_reg - PAD_VELOCITY;
            else
                y_pad_next <= y_pad_reg;
            end if;
        end if;
    end if;
end process Paddle_Control;



Paddle2_Control: process(clk, btn2)
begin
    if rising_edge(clk) then
        if refresh_tick = '1' then
            -- Update the next position based on button input
            if btn2(1) = '1' and ((y_pad2_b) < Y_MAX) then
                y_pad2_next <= ((y_pad2_reg) + PAD_VELOCITY);
            elsif btn2(0) = '1' and ((y_pad2_t) > T_WALL_T) then
                y_pad2_next <= ((y_pad2_reg) - PAD_VELOCITY);
            else
                y_pad2_next <= y_pad2_reg;
            end if;

            -- Update the top and bottom positions based on the new calculated next position
            y_pad2_t <= y_pad2_next;
            y_pad2_b <= ((y_pad2_next) + PAD_HEIGHT - 1);
        end if;
    end if;
end process Paddle2_Control;



    
    -- Convert x_ball_reg and y_ball_reg to unsigned for arithmetic operations, then convert results back to STD_LOGIC_VECTOR
    x_ball_l <= ((x_ball_reg));
    y_ball_t <= ((y_ball_reg));
    x_ball_r <= ((x_ball_l) + (BALL_SIZE) - 1); -- Ensure the length matches your signal size
    y_ball_b <= ((y_ball_t) + (BALL_SIZE) - 1);


    -- Pixel within ROM square boundaries
    sq_ball_on <= '1' when (x_ball_l <= x) and (x <= x_ball_r) and     (y_ball_t <= y) and (y <= y_ball_b) else '0';

    -- Map current pixel location to ROM addr/col
    rom_addr <= ((y(2 downto 0)) - (y_ball_t(2 downto 0)));
    rom_col <= ((x(2 downto 0)) - (x_ball_l(2 downto 0)));
    process(rom_data, rom_col)
begin
    case rom_col is
        when "000" =>
            rom_bit <= rom_data(0); -- First bit for column 0
        when "001" =>
            rom_bit <= rom_data(1); -- Second bit for column 1
        when "010" =>
            rom_bit <= rom_data(2); -- Third bit for column 2
        when "011" =>
            rom_bit <= rom_data(3); -- Fourth bit for column 3
        when "100" =>
            rom_bit <= rom_data(4); -- Fifth bit for column 4
        when "101" =>
            rom_bit <= rom_data(5); -- Sixth bit for column 5
        when "110" =>
            rom_bit <= rom_data(6); -- Seventh bit for column 6
        when "111" =>
            rom_bit <= rom_data(7); -- Eighth bit for column 7
        when others =>
            rom_bit <= '0'; -- Default case, not strictly necessary unless undefined behavior is possible
    end case;
end process;


    -- Pixel within round ball
    ball_on <= sq_ball_on and rom_bit;

    -- New ball position
        process(clk, game_pause)
    begin
        if rising_edge(clk) then
            -- Handle the 'gra_still' condition first
          if game_pause ='0' then
            if gra_still = '1' then
                x_ball_next <= "0100111111";
                y_ball_next <= "0011101111";
            -- Then check for 'refresh_tick'
            elsif refresh_tick = '1' then
                x_ball_next <= ((x_ball_reg) + (x_delta_reg));
                y_ball_next <= ((y_ball_reg) + (y_delta_reg));
            -- Default condition when neither 'gra_still' nor 'refresh_tick' are asserted
            else
                x_ball_next <= x_ball_reg;
                y_ball_next <= y_ball_reg;
            end if;
            
            else 
            x_ball_next <=x_ball_next;
            y_ball_next <= y_ball_next;
        end if;
        
        
        end if;
    end process;

    Collision_Detection: process(x_delta_next, y_delta_next, gra_still)

begin
    hit <= '0';
    miss1 <= '0';
    miss2 <= '0';
    x_delta_next <= x_delta_reg; -- Keep current direction by default
    y_delta_next <= y_delta_reg;

    if gra_still = '1' then
        -- Convert BALL_VELOCITY_NEG and BALL_VELOCITY_POS to the appropriate bit length
        x_delta_next <= (BALL_VELOCITY_NEG);
        y_delta_next <= (BALL_VELOCITY_POS);
    elsif (y_ball_t < T_WALL_B) then
        y_delta_next <= (BALL_VELOCITY_POS); -- Move down
    elsif (y_ball_b > (B_WALL_T)) then
        y_delta_next <= (BALL_VELOCITY_NEG); -- Move up
    elsif (x_ball_l <= L_WALL_R) then
        x_delta_next <= (BALL_VELOCITY_POS); -- Move right
    elsif ((X_PAD_L <= x_ball_r) and 
          (x_ball_r <= X_PAD_R) and 
          (y_pad_t <= y_ball_b) and 
          (y_ball_t <= y_pad_b)) then


    x_delta_next <= (BALL_VELOCITY_NEG);
        hit <= '1';
    elsif ((X_PAD2_L <= x_ball_l) and 
          (x_ball_l <= X_PAD2_R) and 
          (y_pad2_t <= y_ball_b) and 
          (y_ball_t <= y_pad2_b)) then
        x_delta_next <= (BALL_VELOCITY_POS); -- Change direction
        hit <= '1';
    elsif (x_ball_r > X_MAX) then
        miss1 <= '1';
    elsif (x_ball_r < 25) then
        miss2 <= '1';
    end if;
end process Collision_Detection;


    -- Output status signal for graphics
    graph_on <= l_wall_on or t_wall_on or b_wall_on or pad_on or ball_on or pad2_on;

    -- RGB multiplexing circuit
    RGB_Multiplexing: process(video_on, l_wall_on, t_wall_on, b_wall_on, pad_on, ball_on, pad2_on, wall_rgb, pad_rgb, ball_rgb, bg_rgb)
    begin
        if video_on = '0' then
            graph_rgb <= "0000000000000000"; -- No value, blank
        else
            if l_wall_on = '1' or t_wall_on = '1' or b_wall_on = '1' then
                graph_rgb <= wall_rgb; -- Wall color
            elsif pad_on = '1' then
                graph_rgb <= pad_rgb; -- Paddle color
            elsif ball_on = '1' then
                graph_rgb <= ball_rgb; -- Ball color
            elsif pad2_on = '1' then
                graph_rgb <= PAD2_COLOR; -- Specific color for pad2, assuming purple
            else
                graph_rgb <= bg_rgb; -- Background
            end if;
        end if;
    end process RGB_Multiplexing;
end Behavioral;

   
   
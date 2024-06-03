library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all; -- For using unsigned types

entity pong_top is
    Port (
        clk    : in STD_LOGIC;  -- 100MHz
        reset  : in STD_LOGIC;  -- btnR
        MISO, MISO2    : in STD_LOGIC; -- btnD, btnU
        game_pause, game_mode : in STD_LOGIC;
        sensitivity : in std_logic_vector(1 downto 0);
        hsync , SS,SS2, MOSI, MOSI2 : out STD_LOGIC; -- to VGA Connector
        SCLK, SCLK2 : buffer std_logic;
        vsync  : out STD_LOGIC; -- to VGA Connector
        segments : out std_logic_vector(6 downto 0);
        digit_select : BUFFER std_logic;
        rgb    : out STD_LOGIC_VECTOR(15 downto 0) -- to DAC, to VGA Connector
    );
end pong_top;

architecture Behavioral of pong_top is
    signal btn, btn2 : std_logic_vector(1 downto 0);
    component top_ssd_pmod IS
  PORT(
    clk          : IN      STD_LOGIC;                      --system clock
    reset_n      : IN      STD_LOGIC;                      --active low reset
    number       : IN      std_logic;                        --number to display on the 7 segment displays
    digit_select : BUFFER  STD_LOGIC;                      --output to the pmod digit select pin
    segments     : OUT     STD_LOGIC_VECTOR(6 DOWNTO 0));  --outputs to the pmod seven segment displays
END component;
    
    component pmod IS
 
  PORT(
    clk             : IN     STD_LOGIC;                     --system clock
    reset_n         : IN     STD_LOGIC;                     --active low reset
    miso            : IN     STD_LOGIC;                     --SPI master in, slave out
    mosi            : OUT    STD_LOGIC;                     --SPI master out, slave in
    sclk            : BUFFER STD_LOGIC;                     --SPI clock
    cs_n            : OUT    STD_LOGIC;                     --pmod chip select
    trigger_button  : OUT    STD_LOGIC;                     --trigger button status
    center_button   : OUT    STD_LOGIC);                    --center button status
END component;
    -- State declarations for 4 states
    type state_type is (newgame, play, newball, over);
    signal state_reg, state_next: state_type;
    
    -- Signal declaration
    signal w_x, w_y         : std_logic_vector(9 downto 0);
    signal w_vid_on, w_p_tick, graph_on, hit, miss1, miss2 , player_wins: std_logic;
    signal text_on          : std_logic_vector(3 downto 0);
    signal graph_rgb, text_rgb , back_ground : std_logic_vector(15 downto 0);
    signal rgb_reg, rgb_next : std_logic_vector(15 downto 0);
    signal dig0, dig1       : std_logic_vector(3 downto 0);
    signal gra_still, d_inc, d_inc2,  d_clr, timer_start : std_logic;
    signal timer_tick, timer_up : std_logic;
    signal ball_reg, ball_next : std_logic_vector(2 downto 0);
    
    --Components decalation
    component vga_controller is
    Port (
        clk_100MHz : in STD_LOGIC;
        reset      : in STD_LOGIC;
        video_on   : out STD_LOGIC;
        hsync      : out STD_LOGIC;
        vsync      : out STD_LOGIC;
        p_tick     : out STD_LOGIC;
        x          : out STD_LOGIC_VECTOR(9 downto 0);
        y          : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

    component pong_text is
    Port (
        clk  ,player_wins    : in STD_LOGIC;
        ball     : in STD_LOGIC_VECTOR(2 downto 0);
        dig0     : in STD_LOGIC_VECTOR(3 downto 0);
        dig1     : in STD_LOGIC_VECTOR(3 downto 0);
        x        : in STD_LOGIC_VECTOR(9 downto 0);
        game_mode : in std_logic;
        y        : in STD_LOGIC_VECTOR(9 downto 0);
        text_on  : out STD_LOGIC_VECTOR(3 downto 0);
        text_rgb : out STD_LOGIC_VECTOR(15 downto 0)
    );
end component;

    component pong_graph is
    Port (
        clk        : in STD_LOGIC;
        reset      : in STD_LOGIC;
        btn        : in STD_LOGIC_VECTOR(1 downto 0); -- btn(0) = up, btn(1) = down for Player One
        btn2       : in STD_LOGIC_VECTOR(1 downto 0); -- btn2(0) = up, btn2(1) = down for Player Two
        gra_still  : in STD_LOGIC;                    -- Still graphics
        game_pause : in STD_LOGIC;                    -- Pause input
        video_on   : in STD_LOGIC;
        background : in std_logic;
        sensitivity : in std_logic_vector(1 downto 0);
        x          : in STD_LOGIC_VECTOR(9 downto 0);
        y          : in STD_LOGIC_VECTOR(9 downto 0);
        graph_on   : out STD_LOGIC;
        hit        : out STD_LOGIC;                    -- Ball hit
        miss1, miss2       : out STD_LOGIC;                    -- Ball miss
        graph_rgb  : out STD_LOGIC_VECTOR(15 downto 0) -- RGB graphics output
    );
end component;

    component m100_counter is
    Port ( 
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        d_inc, d_inc2 : in  STD_LOGIC; -- Increment signal
        d_clr : in  STD_LOGIC; -- Clear signal
        dig0  : out STD_LOGIC_VECTOR(3 downto 0); -- Least significant digit
        dig1  : out STD_LOGIC_VECTOR(3 downto 0)  -- Most significant digit
    );
end component;

    component timer is
    Port ( 
        clk         : in STD_LOGIC;
        reset       : in STD_LOGIC;
        timer_start : in STD_LOGIC;
        timer_tick  : in STD_LOGIC;
        timer_up    : out STD_LOGIC
    );
end component;
begin

    --PMOD
   
   SSD: top_ssd_pmod 
  PORT MAP(
    clk => clk,
    reset_n  => reset,
    number   => game_mode,
    digit_select => digit_select,
    segments  => segments
    );
   
    PMOD_joy :pmod port map(
    clk => clk,
    reset_n => reset,
    miso => MISO,
    cs_n => SS,
    mosi => MOSI,
    sclk => SCLK,
    trigger_button => btn(0),
    center_button => btn(1)
    );
    
    PMOD_joy2 :pmod port map(
    clk => clk,
    reset_n => reset,
    miso => MISO2,
    cs_n => SS2,
    mosi => MOSI2,
    sclk => SCLK2,
    trigger_button => btn2(0),
    center_button => btn2(1)
    );

    -- VGA Controller instantiation
    vga_unit: vga_controller
        port map (
            clk_100MHz => clk,
            reset      => reset,
            video_on   => w_vid_on,
            hsync      => hsync,
            vsync      => vsync,
            p_tick     => w_p_tick,
            x          => w_x,
            y          => w_y
        );

    -- Pong Text instantiation
    text_unit: pong_text
        port map (
            clk      => clk,
            player_wins => player_wins,
            x        => w_x,
            y        => w_y,
            dig0     => dig0,
            game_mode => game_mode,
            dig1     => dig1,
            ball     => ball_reg,
            text_on  => text_on,
            text_rgb => text_rgb
        );

    -- Pong Graphics instantiation
    graph_unit: pong_graph
        port map (
            clk       => clk,
            reset     => reset,
            btn       => btn,
            btn2      => btn2,
            gra_still => gra_still,
            game_pause => game_pause,
            video_on  => w_vid_on,
            x         => w_x,
            y         => w_y,
            sensitivity => sensitivity,
            background => game_mode,
            hit       => hit,
            miss1      => miss1,
            miss2     => miss2,
            graph_on  => graph_on,
            graph_rgb => graph_rgb
        );

    -- 60 Hz tick when screen is refreshed
timer_tick_process : process(w_x, w_y)
begin
    if (w_x = 0) and (w_y = 0) then
        timer_tick <= '1';
    else
        timer_tick <= '0';
    end if;
end process timer_tick_process;

-- Timer instantiation
timer_unit : entity work.timer
    port map (
        clk        => clk,
        reset      => reset,
        timer_tick => timer_tick,
        timer_start => timer_start,
        timer_up   => timer_up
    );

-- m100_counter instantiation
counter_unit : entity work.m100_counter
    port map (
        clk   => clk,
        reset => reset,
        d_inc => d_inc,
        d_inc2 => d_inc2,
        d_clr => d_clr,
        dig0  => dig0,
        dig1  => dig1
    );

    FSMD_Process: process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= newgame;
            ball_reg <= "000"; -- Assuming ball_reg is 3 bits as previously declared
            rgb_reg <= (others => '0'); -- Resetting RGB register to all zeros
        elsif rising_edge(clk) then
            state_reg <= state_next;
            ball_reg <= ball_next;
            if w_p_tick = '1' then
                rgb_reg <= rgb_next;
            end if;
        end if;
    end process FSMD_Process;
    
    
    FSMD_Next_State_Logic: process(state_reg, ball_reg, btn, btn2, hit, miss1, miss2,  timer_up)
    begin
        -- Default assignments
        gra_still <= '1'; -- Still graphic by default
        timer_start <= '0'; -- Timer not started by default
        d_inc <= '0'; -- Score increment disabled by default
        d_inc2 <= '0';-- Score increment disabled by default
        d_clr <= '0'; -- Score clear disabled by default
        state_next <= state_reg; -- Default to staying in the current state
        ball_next <= ball_reg; -- Default to keeping the current ball count
        
        -- State transition logic
        case state_reg is
            when newgame =>
                ball_next <= "101"; -- Five balls
                d_clr <= '1'; -- Clear score
                -- Transition to play if any button is pressed
                if btn /= "00" or btn2 /= "00" then
                    state_next <= play;
                    ball_next <= ((ball_reg) - 1); -- Decrement ball count
                end if;
                
            when play =>
                gra_still <= '0'; -- Animated screen
                
                if miss1 = '1' then
                d_inc2 <= '1';
                    if (ball_reg) = 0 then
                        state_next <= over;
                    else
                        state_next <= newball;
                         timer_start <= '1'; -- Start 2-second timer
                    ball_next <= ((ball_reg) - 1); -- Decrement ball count
                    end if;
                elsif miss2 = '1' then
                d_inc <= '1';
                    if (ball_reg) = 0 then
                        state_next <= over;
                    else
                        state_next <= newball;
                    end if;
                    timer_start <= '1'; -- Start 2-second timer
                    ball_next <= ((ball_reg) - 1); -- Decrement ball count
                end if;
                
            when newball =>
                -- Wait for 2 seconds and until any button is pressed to continue
                if timer_up = '1' and btn /= "00" then
                    state_next <= play;
                end if;
                
            when over =>
                -- Wait 2 seconds to display game over then reset to newgame
                if dig0 < dig1 then 
                player_wins <= '0';
                
                else
                player_wins <= '1';
                end if;
                
                if timer_up = '1' then
                    state_next <= newgame;
                end if;
                
            when others =>
                null; -- In VHDL, others must be handled, but here it does nothing.
        end case;
    end process FSMD_Next_State_Logic;
    
    --background
    process (game_mode)
    begin
    if(game_mode = '1') then
    back_ground <= "0000011111111111";
    
    else
    back_ground <= "1111100011100111";
    
    end if;
    
    end process;
    
    -- RGB Multiplexing
    RGB_Multiplexing : process(w_vid_on, text_on, state_reg, text_rgb, graph_on, graph_rgb)
    begin
        if w_vid_on = '0' then
            rgb_next <= (others => '0'); -- Blank
        else
            if text_on(3) = '1' or ((state_reg = newgame) and text_on(1) = '1') or ((state_reg = over) and text_on(0) = '1') then
                
                rgb_next <= text_rgb; -- Colors in pong_text
                
            elsif graph_on = '1' then
            
                rgb_next <= graph_rgb; -- Colors in pong_graph
               
            elsif text_on(2) = '1' then
           
                rgb_next <= text_rgb; -- Colors in pong_text
                
            else
                rgb_next <= back_ground; -- Aqua background
            end if;
        end if;
    end process RGB_Multiplexing;

    -- Output Assignment
    rgb <= rgb_reg;
end Behavioral;

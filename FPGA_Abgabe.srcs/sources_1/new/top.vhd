----------------------------------------------------------------------------------
-- PONG GAME FINAL - 3 Balls Total & Green Life Bar
-- 
-- OVERVIEW:
-- This module generates a 1920x1080 VGA signal.
-- It implements a Pong game with a Welcome Screen, Scoreboard, and Physics.
-- Rules: The game ends after 3 balls are played in total.
--
-- REQUIREMENTS:
-- 1. Clock Wizard IP: Input 100MHz -> Output 148.5MHz (named clk_wiz_0).
-- 2. Constraints: Map 'btn' to buttons and 'sw' to a switch.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all; -- Allows math on std_logic_vectors
use IEEE.NUMERIC_STD.ALL;        -- Standard numeric operations
use work.constants_pkg.all;

entity top is
    Port ( 
           CLK_I : in  STD_LOGIC; -- System Clock (100 MHz)
           
           -- Buttons: [3] Right Up, [2] Right Down, [1] Left Up, [0] Left Down
           btn   : in  STD_LOGIC_VECTOR (3 downto 0);
           
           -- Switch: [0] Reset / Force Welcome Screen
           sw    : in  STD_LOGIC_VECTOR (0 downto 0); 
           
           -- VGA Physical Outputs
           VGA_HS_O : out  STD_LOGIC;
           VGA_VS_O : out  STD_LOGIC;
           VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_G : out  STD_LOGIC_VECTOR (3 downto 0)
           );
end top;

architecture Behavioral of top is

    -- Component Declaration for the Clock Wizard
    -- This IP core must be generated in Vivado IP Catalog
    component clk_wiz_0
    port ( 
        CLK_IN1 : in std_logic; 
        CLK_OUT1 : out std_logic 
    );
    end component;
    
<<<<<<< HEAD
    constant H_FP : natural := 88; -- Horizontal Front Porch
    constant H_PW : natural := 44; -- Horizontal Pulse Width
    constant H_MAX : natural := 2200; -- Total Pixel Clocks per Line
    
    constant V_FP : natural := 4;  -- Vertical Front Porch
    constant V_PW : natural := 5;  -- Vertical Pulse Width
    constant V_MAX : natural := 1125; -- Total Lines per Frame
    
    constant H_POL : std_logic := '1'; -- Sync Polarity (Positive for 1080p)
    constant V_POL : std_logic := '1';

    -------------------------------------------------------------------------
    -- GAME DESIGN CONSTANTS
    -------------------------------------------------------------------------
    constant BALL_SIZE : natural := 20;    -- Size of ball in pixels
    constant PADDLE_W  : natural := 25;    -- Width of paddle
    constant PADDLE_H  : natural := 180;   -- Height of paddle
    constant PADDLE_OFFSET : natural := 60; -- Distance from edge of screen
    
    -- SPEED CONTROL
    -- Higher number = Slower Game.
    -- 2,500,000 is the comfortable/slow speed.
    constant GAME_CLK_DIV : natural := 2000000; 
=======
>>>>>>> 0cedb40af83f68fe95bf590ebe6e0081604ee750

    -- SIGNAL DECLARATIONS
    signal pxl_clk : std_logic; -- The 148.5 MHz pixel clock
    signal active : std_logic;  -- '1' when we are drawing visible pixels
    
    -- VGA Counters
    signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    

    -- State Machine Definition
    -- (Type is inherited from constants_pkg)
    signal state : state_type := IDLE;
    
    -- Object Coordinates (12-bit vectors to hold positions up to 2200)
    signal ball_x : std_logic_vector(11 downto 0) := x"3C0"; -- Center X
    signal ball_y : std_logic_vector(11 downto 0) := x"21C"; -- Center Y
    
    signal pad_l_y : std_logic_vector(11 downto 0) := x"1C2"; -- Left Paddle Y
    signal pad_r_y : std_logic_vector(11 downto 0) := x"1C2"; -- Right Paddle Y (450)
    
    -- Scoring & Lives
    signal lives : integer range 0 to 3 := 3; -- Total Balls per session
    signal score_l : integer range 0 to 9 := 0;
    signal score_r : integer range 0 to 9 := 0;


begin

    -- Instantiate the Clock Wizard to get 148.5 MHz from 100 MHz
    clk_div_inst : clk_wiz_0 
    port map (
        CLK_IN1 => CLK_I, 
        CLK_OUT1 => pxl_clk
    );
    
    
    -------------------------------------------------------------------------
    -- INSTANCE: VGA TIMING MODULE
    -------------------------------------------------------------------------
    -- This replaces the manual counters and sync processes
    vga_inst : vga_timing_1080p
    port map (
        clk_pxl  => pxl_clk,    -- Connect 148.5MHz clock
        h_sync   => VGA_HS_O,   -- Connect directly to Output Port
        v_sync   => VGA_VS_O,   -- Connect directly to Output Port
        pixel_x  => h_cntr_reg, -- Wire internal x to your existing signal
        pixel_y  => v_cntr_reg, -- Wire internal y to your existing signal
        video_on => active      -- Wire video active to your existing signal
    );
    
    
    -------------------------------------------------------------------------
    -- INSTANCE: DRAWING ENGINE
    -------------------------------------------------------------------------
<<<<<<< HEAD
    -- This handles movement, collisions, and game rules.
    process (pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            
            -- HARD RESET SWITCH (Sw 0)
            if sw(0) = '1' then 
                state <= IDLE;
                lives <= 3;
                score_l <= 0; score_r <= 0;
                -- Center everything
                ball_x <= std_logic_vector(to_unsigned(960, 12));
                ball_y <= std_logic_vector(to_unsigned(540, 12));
                pad_l_y <= std_logic_vector(to_unsigned(450, 12));
                pad_r_y <= std_logic_vector(to_unsigned(450, 12));
            
            -- PHYSICS UPDATE (Only happens when game_tick is 1)
            elsif game_tick = '1' then
                case state is
                    
                    -- STATE: WELCOME SCREEN
                    when IDLE =>
                        -- Wait for ANY button to start the game
                        if btn /= "0000" then 
                            state <= SERVE; 
                        end if;

                    -- STATE: SERVE (Wait for player to launch ball)
                    when SERVE =>
                        -- Reset Ball to Center
                        ball_x <= std_logic_vector(to_unsigned(960, 12));
                        ball_y <= std_logic_vector(to_unsigned(540, 12));
                        
                        -- If Up buttons are pressed, launch ball
                        if btn(3)='1' or btn(1)='1' then 
                             state <= PLAY; 
                        end if;

                    -- STATE: PLAY (The actual game)
                    when PLAY =>
                        ------------------------
                        -- 1. PADDLE LOGIC
                        ------------------------
                        -- Left Paddle (Buttons 0 & 1)
                        if btn(1) = '1' and pad_l_y > 20 then -- WHY 20?
                            pad_l_y <= pad_l_y - 4; 
                        end if;
                        if btn(0) = '1' and pad_l_y < 900 then 
                            pad_l_y <= pad_l_y + 4; 
                        end if;
                        
                        -- Right Paddle (Buttons 2 & 3)
                        if btn(3) = '1' and pad_r_y > 20 then 
                            pad_r_y <= pad_r_y - 4; 
                        end if;
                        if btn(2) = '1' and pad_r_y < 900 then 
                            pad_r_y <= pad_r_y + 4; 
                        end if;
                        
                        ------------------------
                        -- 2. BALL Y MOVEMENT
                        ------------------------
                        if ball_dy = '1' then -- Moving Down
                            if ball_y >= (FRAME_HEIGHT - BALL_SIZE - 10) then 
                                ball_dy <= '0'; -- Hit Bottom, Bounce Up
                            else 
                                ball_y <= ball_y + 3; 
                            end if;
                        else -- Moving Up
                            if ball_y <= 10 then 
                                ball_dy <= '1'; -- Hit Top, Bounce Down
                            else 
                                ball_y <= ball_y - 3; 
                            end if;
                        end if;
                        
                        ------------------------
                        -- 3. BALL X MOVEMENT & COLLISION
                        ------------------------
                        if ball_dx = '1' then -- Moving Right
                            
                            -- Check Collision with Right Paddle
                            if (ball_x + BALL_SIZE) >= (FRAME_WIDTH - PADDLE_OFFSET - PADDLE_W) and --left side paddle boundary
                               (ball_x + BALL_SIZE) <= (FRAME_WIDTH - PADDLE_OFFSET) and -- right side
                               (ball_y + BALL_SIZE >= pad_r_y) and (ball_y <= pad_r_y + PADDLE_H) then
                                ball_dx <= '0'; -- Bounce Left
                            
                            -- Check Goal (Ball went past paddle)
                            elsif ball_x >= (FRAME_WIDTH - BALL_SIZE - 5) then
                                -- Update Score
                                if score_l < 9 then score_l <= score_l + 1; end if;
                                
                                -- Handle Lives logic
                                if lives = 1 then -- Last ball just died
                                    lives <= 0;
                                    state <= GAMEOVER;
                                else
                                    lives <= lives - 1;
                                    state <= SERVE;
                                end if;
                            else
                                ball_x <= ball_x + 3; -- Continue moving Right
                            end if;

                        else -- Moving Left
                            
                            -- Check Collision with Left Paddle
                            if ball_x <= (PADDLE_OFFSET + PADDLE_W) and ball_x >= PADDLE_OFFSET and
                               (ball_y + BALL_SIZE >= pad_l_y) and (ball_y <= pad_l_y + PADDLE_H) then
                                ball_dx <= '1'; -- Bounce Right
                                
                            -- Check Goal
                            elsif ball_x <= 5 then
                                -- Update Score
                                if score_r < 9 then score_r <= score_r + 1; end if;
                                
                                -- Handle Lives logic
                                if lives = 1 then -- Last ball just died
                                    lives <= 0;
                                    state <= GAMEOVER;
                                else
                                    lives <= lives - 1;
                                    state <= SERVE;
                                end if;
                            else
                                ball_x <= ball_x - 3; -- Continue moving Left
                            end if;
                        end if;

                    -- STATE: GAME OVER
                    when GAMEOVER =>
                        -- Press all buttons to reset
                        if btn = "1111" then 
                            state <= IDLE; 
                            lives <= 3;
                            score_l <= 0; score_r <= 0; 
                        end if;

                end case;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- PROCESS 3: TEXT ENGINE
    -------------------------------------------------------------------------
    -- This process checks the current pixel coordinates (h_cntr, v_cntr)
    -- and decides if we are drawing text (Welcome or Score).
    process(h_cntr_reg, v_cntr_reg, score_l, score_r, state, char_selection)
        variable scaled_y : integer;
        variable char_col_idx : integer;
    begin
        draw_text_pixel <= '0'; -- Default to no text
        char_selection <= 0; 
        scaled_y := 0;
        char_col_idx := -1;
=======
    draw_inst : draw
    port map (
        clk_pxl    => pxl_clk,
        video_on   => active,      -- Connect to the signal from VGA module
        pixel_x    => h_cntr_reg,  -- Connect to signal from VGA module
        pixel_y    => v_cntr_reg,  -- Connect to signal from VGA module
>>>>>>> 0cedb40af83f68fe95bf590ebe6e0081604ee750
        
        -- Connect Game Objects
        ball_x     => ball_x,
        ball_y     => ball_y,
        pad_l_y    => pad_l_y,
        pad_r_y    => pad_r_y,
        score_l    => score_l,
        score_r    => score_r,
        lives      => lives,
        
        -- Connect State Helper
        game_state => state,
        
        -- Connect Physical Outputs
        vga_r      => VGA_R,
        vga_g      => VGA_G,
        vga_b      => VGA_B
    );

    -------------------------------------------------------------------------
    --INSTANCE: GAME LOGIC 
    -------------------------------------------------------------------------
    logic_inst : game_logic
    port map (
        clk_pxl   => pxl_clk,
        rst       => sw(0),      -- Map Switch 0 to Reset
        btn       => btn,        -- Map Buttons
        
        -- Outputs (Driving the wires)
        ball_x    => ball_x,
        ball_y    => ball_y,
        pad_l_y   => pad_l_y,
        pad_r_y   => pad_r_y,
        score_l   => score_l,
        score_r   => score_r,
        lives     => lives,
        game_state_out => state
    );
    

end Behavioral;
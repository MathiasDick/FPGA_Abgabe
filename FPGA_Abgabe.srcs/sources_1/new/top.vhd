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
           
           LEFT_P_UP : in STD_LOGIC;
           LEFT_P_DOWN : in STD_LOGIC;
           RIGHT_P_UP : in STD_LOGIC;
           RIGHT_P_DOWN : in STD_LOGIC;
           
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
    

    -- SIGNAL DECLARATIONS
    signal pxl_clk : std_logic; -- The 148.5 MHz pixel clock
    signal active : std_logic;  -- '1' when we are drawing visible pixels
    
    -- VGA Counters
    signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    

    -- State Machine Definition
    -- (Type is inherited from constants_pkg)
    signal state : state_type := WELCOME;
    
    -- Object Coordinates (12-bit vectors to hold positions up to 2200)
    signal ball_x : std_logic_vector(11 downto 0) := x"3C0"; -- Center X
    signal ball_y : std_logic_vector(11 downto 0) := x"21C"; -- Center Y
    
    signal pad_l_y : std_logic_vector(11 downto 0) := x"1C2"; -- Left Paddle Y
    signal pad_r_y : std_logic_vector(11 downto 0) := x"1C2"; -- Right Paddle Y
    
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
    draw_inst : draw
    port map (
        clk_pxl    => pxl_clk,
        video_on   => active,      -- Connect to the signal from VGA module
        pixel_x    => h_cntr_reg,  -- Connect to signal from VGA module
        pixel_y    => v_cntr_reg,  -- Connect to signal from VGA module
        
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
        LEFT_P_UP       => LEFT_P_UP,        -- Map Buttons
        LEFT_P_DOWN     => LEFT_P_DOWN,
        RIGHT_P_UP      => RIGHT_P_UP,
        RIGHT_P_DOWN    => RIGHT_P_DOWN,
        
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
----------------------------------------------------------------------------------
-- PONG GAME - Top Level Module
-- 
-- DESCRIPTION:
-- Implements a complete Pong game with 1920x1080 VGA output.
-- Features welcome screen, gameplay, scoring system, and game over screen.
-- Game ends after player loses all 3 lives.
--
-- HARDWARE REQUIREMENTS:
-- - Clock Wizard IP: Converts 100MHz input to 148.5MHz pixel clock (clk_wiz_0)
-- - Constraints file must map button inputs and reset switch
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity top is
    Port ( 
           CLK_I : in  STD_LOGIC;  -- System clock input (100 MHz)
           
           -- Player control inputs
           LEFT_P_UP : in STD_LOGIC;
           LEFT_P_DOWN : in STD_LOGIC;
           RIGHT_P_UP : in STD_LOGIC;
           RIGHT_P_DOWN : in STD_LOGIC;
           
           RESET : in  STD_LOGIC;  -- Reset switch: Returns game to WELCOME state
           
           -- VGA output signals
           VGA_HS_O : out  STD_LOGIC;
           VGA_VS_O : out  STD_LOGIC;
           VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_G : out  STD_LOGIC_VECTOR (3 downto 0)
           );
end top;

architecture Behavioral of top is

    -------------------------------------------------------------------------
    -- Clock Wizard IP Component
    -------------------------------------------------------------------------
    component clk_wiz_0
    port ( 
        CLK_IN1 : in std_logic; 
        CLK_OUT1 : out std_logic 
    );
    end component;
    
    -------------------------------------------------------------------------
    -- Internal Signals
    -------------------------------------------------------------------------
    signal pxl_clk : std_logic;  -- 148.5 MHz pixel clock for VGA timing
    signal active : std_logic;   -- Video active region flag
    
    -- VGA timing counters
    signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    
    -- Game state
    signal state : state_type := WELCOME;
    
    -- Game object positions
    signal ball_x  : integer range 0 to 4095 := (FRAME_WIDTH / 2) - (BALL_SIZE / 2);
    signal ball_y  : integer range 0 to 4095 := (FRAME_HEIGHT / 2) - (BALL_SIZE / 2);
    
    signal pad_l_y : integer range 0 to 4095 := (FRAME_HEIGHT / 2) - (PADDLE_H / 2);
    signal pad_r_y : integer range 0 to 4095 := (FRAME_HEIGHT / 2) - (PADDLE_H / 2);
    
    -- Score and lives tracking
    signal lives : integer range 0 to 3 := 3;
    signal score_l : integer range 0 to 3 := 0;
    signal score_r : integer range 0 to 3 := 0;


begin

    -------------------------------------------------------------------------
    -- Clock Generation: 100 MHz to 148.5 MHz
    -------------------------------------------------------------------------
    clk_div_inst : clk_wiz_0 
    port map (
        CLK_IN1 => CLK_I, 
        CLK_OUT1 => pxl_clk
    );
    
    
    -------------------------------------------------------------------------
    -- VGA Timing Generator (1920x1080 @ 60Hz)
    -------------------------------------------------------------------------
    vga_inst : vga_timing_1080p
    port map (
        clk_pxl  => pxl_clk,
        h_sync   => VGA_HS_O,
        v_sync   => VGA_VS_O,
        pixel_x  => h_cntr_reg,
        pixel_y  => v_cntr_reg,
        video_on => active
    );
    
    
    -------------------------------------------------------------------------
    -- Graphics Renderer
    -------------------------------------------------------------------------
    draw_inst : draw
    port map (
        clk_pxl    => pxl_clk,
        video_on   => active,
        pixel_x    => h_cntr_reg,
        pixel_y    => v_cntr_reg,
        
        -- Game object positions
        ball_x     => ball_x,
        ball_y     => ball_y,
        pad_l_y    => pad_l_y,
        pad_r_y    => pad_r_y,
        score_l    => score_l,
        score_r    => score_r,
        lives      => lives,
        
        game_state => state,
        
        -- VGA color outputs
        vga_r      => VGA_R,
        vga_g      => VGA_G,
        vga_b      => VGA_B
    );

    -------------------------------------------------------------------------
    -- Game Physics and Logic Controller
    -------------------------------------------------------------------------
    logic_inst : game_logic
    port map (
        clk_pxl        => pxl_clk,
        rst            => RESET,
        LEFT_P_UP      => LEFT_P_UP,
        LEFT_P_DOWN    => LEFT_P_DOWN,
        RIGHT_P_UP     => RIGHT_P_UP,
        RIGHT_P_DOWN   => RIGHT_P_DOWN,
        
        -- Position outputs
        ball_x         => ball_x,
        ball_y         => ball_y,
        pad_l_y        => pad_l_y,
        pad_r_y        => pad_r_y,
        
        -- Game state outputs
        score_l        => score_l,
        score_r        => score_r,
        lives          => lives,
        game_state_out => state
    );
    

end Behavioral;
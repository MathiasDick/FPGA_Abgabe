----------------------------------------------------------------------------------
-- Constants Package
-- 
-- DESCRIPTION:
-- Central location for all game constants, type definitions, and component
-- declarations. Ensures consistency across all modules.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package constants_pkg is

    -------------------------------------------------------------------------
    -- State Machine Type Definition
    -------------------------------------------------------------------------
    type state_type is (WELCOME, SERVE, PLAY, GAMEOVER);

    -------------------------------------------------------------------------
    -- Game Constants
    -------------------------------------------------------------------------
    -- Display dimensions
    constant FRAME_WIDTH   : natural := 1920;
    constant FRAME_HEIGHT  : natural := 1080;
    
    -- Game object dimensions
    constant BALL_SIZE     : natural := 20;  -- Ball width and height
    constant PADDLE_W      : natural := 25;  -- Paddle width
    constant PADDLE_H      : natural := 180; -- Paddle height
    constant PADDLE_OFFSET : natural := 60;  -- Paddle distance from screen edge
    
    -- Game rules
    constant MAX_LIVES     : natural := 3;   -- Total lives per game
    
    -- Movement speed control (clock dividers)
    constant BALL_CLK_DIV   : natural := 480000;  -- Ball update frequency (~309 Hz at 148.5 MHz)
    constant PADDLE_CLK_DIV : natural := 600000;  -- Paddle update frequency (~247 Hz at 148.5 MHz)

    -------------------------------------------------------------------------
    -- Component Declarations
    -------------------------------------------------------------------------
    component vga_timing_1080p
    Port ( clk_pxl  : in  STD_LOGIC;
           h_sync   : out STD_LOGIC;
           v_sync   : out STD_LOGIC;
           pixel_x  : out STD_LOGIC_VECTOR(11 downto 0);
           pixel_y  : out STD_LOGIC_VECTOR(11 downto 0);
           video_on : out STD_LOGIC);
    end component;

    component draw
    Port ( clk_pxl    : in  STD_LOGIC;
           video_on   : in  STD_LOGIC;
           pixel_x    : in  STD_LOGIC_VECTOR(11 downto 0);
           pixel_y    : in  STD_LOGIC_VECTOR(11 downto 0);
           ball_x     : in  integer range 0 to 4095;
           ball_y     : in  integer range 0 to 4095;
           pad_l_y    : in  integer range 0 to 4095;
           pad_r_y    : in  integer range 0 to 4095;
           score_l    : in  integer;
           score_r    : in  integer;
           lives      : in  integer;
           game_state : in  state_type;
           vga_r      : out STD_LOGIC_VECTOR(3 downto 0);
           vga_b      : out STD_LOGIC_VECTOR(3 downto 0);
           vga_g      : out STD_LOGIC_VECTOR(3 downto 0));
    end component;
        
    component game_logic
    Port ( clk_pxl   : in  STD_LOGIC;
           rst       : in  STD_LOGIC;
           LEFT_P_UP : in STD_LOGIC;
           LEFT_P_DOWN : in STD_LOGIC;
           RIGHT_P_UP : in STD_LOGIC;
           RIGHT_P_DOWN : in STD_LOGIC;
           ball_x    : out integer range 0 to 4095;
           ball_y    : out integer range 0 to 4095;
           pad_l_y   : out integer range 0 to 4095;
           pad_r_y   : out integer range 0 to 4095;
           score_l   : out integer range 0 to 3;
           score_r   : out integer range 0 to 3;
           lives     : out integer range 0 to 3;
           game_state_out : out state_type
           );
    end component;
    

end package constants_pkg;

package body constants_pkg is
    -- Package body not required for constants and type definitions
end package body constants_pkg;

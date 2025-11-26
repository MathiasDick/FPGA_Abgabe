library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package constants_pkg is

    -------------------------------------------------------------------------
    -- 1. STATE MACHINE
    -------------------------------------------------------------------------
    type state_type is (IDLE, PLAY, SERVE, GAMEOVER);

    -------------------------------------------------------------------------
    -- 2. GAME CONSTANTS (Single Source of Truth)
    -------------------------------------------------------------------------
    -- Screen Dimensions
    constant FRAME_WIDTH   : natural := 1920;
    constant FRAME_HEIGHT  : natural := 1080;
    
    -- Object Dimensions
    constant BALL_SIZE     : natural := 20;
    constant PADDLE_W      : natural := 25;
    constant PADDLE_H      : natural := 180;
    constant PADDLE_OFFSET : natural := 60;
    
    -- Game Settings
    constant MAX_LIVES     : natural := 3;
    constant GAME_CLK_DIV  : natural := 2500000; -- Speed control

    -------------------------------------------------------------------------
    -- 3. COLOR PALETTE (4-bit per channel)
    -------------------------------------------------------------------------
    constant C_WHITE   : std_logic_vector(3 downto 0) := "1111";
    constant C_BLACK   : std_logic_vector(3 downto 0) := "0000";
    constant C_RED     : std_logic_vector(3 downto 0) := "1111"; -- Adjust if using RGB vs VGA port mapping
    constant C_GREEN   : std_logic_vector(3 downto 0) := "1111"; 
    constant C_BLUE    : std_logic_vector(3 downto 0) := "1111"; 
    -- (Note: You previously used "0011" for dark blue, adjust as you see fit)

    -------------------------------------------------------------------------
    -- 4. COMPONENT DECLARATIONS (Cleans up Top Level)
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
           ball_x     : in  STD_LOGIC_VECTOR(11 downto 0);
           ball_y     : in  STD_LOGIC_VECTOR(11 downto 0);
           pad_l_y    : in  STD_LOGIC_VECTOR(11 downto 0);
           pad_r_y    : in  STD_LOGIC_VECTOR(11 downto 0);
           score_l    : in  integer;
           score_r    : in  integer;
           lives      : in  integer;
           game_state : in  state_type; -- Uses the type defined above!
           vga_r      : out STD_LOGIC_VECTOR(3 downto 0);
           vga_b      : out STD_LOGIC_VECTOR(3 downto 0);
           vga_g      : out STD_LOGIC_VECTOR(3 downto 0));
    end component;
        
    component game_logic
    Port ( clk_pxl   : in  STD_LOGIC;
           rst       : in  STD_LOGIC;
           btn       : in  STD_LOGIC_VECTOR(3 downto 0);
           ball_x    : out STD_LOGIC_VECTOR(11 downto 0);
           ball_y    : out STD_LOGIC_VECTOR(11 downto 0);
           pad_l_y   : out STD_LOGIC_VECTOR(11 downto 0);
           pad_r_y   : out STD_LOGIC_VECTOR(11 downto 0);
           score_l   : out integer range 0 to 9;
           score_r   : out integer range 0 to 9;
           lives     : out integer range 0 to 3;
           game_state_out : out state_type
           );
    end component;
    

end package constants_pkg;

package body constants_pkg is
    -- Nothing needed here for simple constants
end package body constants_pkg;

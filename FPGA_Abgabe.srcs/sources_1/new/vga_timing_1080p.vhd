----------------------------------------------------------------------------------
-- VGA Timing Generator for 1920x1080 @ 60Hz
-- 
-- DESCRIPTION:
-- Generates horizontal and vertical sync signals for 1920x1080 resolution.
-- Requires 148.5 MHz pixel clock.
-- Outputs current pixel coordinates and video active signal.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity vga_timing_1080p is
    Port ( clk_pxl  : in  STD_LOGIC;  -- 148.5 MHz pixel clock
           h_sync   : out STD_LOGIC;  -- Horizontal sync
           v_sync   : out STD_LOGIC;  -- Vertical sync
           pixel_x  : out STD_LOGIC_VECTOR(11 downto 0);  -- Current X coordinate
           pixel_y  : out STD_LOGIC_VECTOR(11 downto 0);  -- Current Y coordinate
           video_on : out STD_LOGIC); -- Active video region flag
end vga_timing_1080p;

architecture Behavioral of vga_timing_1080p is

    -------------------------------------------------------------------------
    -- VGA Timing Constants (1920x1080 @ 60Hz)
    -------------------------------------------------------------------------
    constant COORD_BITS : natural := 12;  -- Bit width for coordinates

    -- Horizontal timing parameters
    constant H_FP  : natural := 88;   -- Horizontal front porch
    constant H_PW  : natural := 44;   -- Horizontal sync pulse width
    constant H_MAX : natural := 2200; -- Total horizontal period
    
    -- Vertical timing parameters
    constant V_FP  : natural := 4;    -- Vertical front porch
    constant V_PW  : natural := 5;    -- Vertical sync pulse width
    constant V_MAX : natural := 1125; -- Total vertical period
    
    -- Sync polarity
    constant H_POL : std_logic := '1';  -- Horizontal sync active high
    constant V_POL : std_logic := '1';  -- Vertical sync active high

    -------------------------------------------------------------------------
    -- Internal Signals
    -------------------------------------------------------------------------
    signal h_cntr : natural range 0 to H_MAX - 1 := 0;  -- Horizontal counter
    signal v_cntr : natural range 0 to V_MAX - 1 := 0;  -- Vertical counter
    signal active : std_logic := '0';                    -- Video active flag

begin

    -------------------------------------------------------------------------
    -- Pixel Counter Process
    -- Increments horizontal and vertical counters for each pixel clock
    -------------------------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            if h_cntr = (H_MAX - 1) then
                h_cntr <= 0;
                if v_cntr = (V_MAX - 1) then
                    v_cntr <= 0;
                else
                    v_cntr <= v_cntr + 1;
                end if;
            else
                h_cntr <= h_cntr + 1;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Sync Signal Generation and Output Assignment
    -------------------------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            -- Generate horizontal sync pulse
            if (h_cntr >= (FRAME_WIDTH + H_FP)) and (h_cntr < (FRAME_WIDTH + H_FP + H_PW)) then
                h_sync <= H_POL;
            else
                h_sync <= not H_POL;
            end if;

            -- Generate vertical sync pulse
            if (v_cntr >= (FRAME_HEIGHT + V_FP)) and (v_cntr < (FRAME_HEIGHT + V_FP + V_PW)) then
                v_sync <= V_POL;
            else
                v_sync <= not V_POL;
            end if;
            
            -- Determine if current pixel is in visible area
            if (h_cntr < FRAME_WIDTH) and (v_cntr < FRAME_HEIGHT) then
                active <= '1';
            else
                active <= '0';
            end if;
            
            -- Output assignments
            video_on <= active;
            pixel_x  <= std_logic_vector(to_unsigned(h_cntr, COORD_BITS));
            pixel_y  <= std_logic_vector(to_unsigned(v_cntr, COORD_BITS));
        end if;
    end process;

end Behavioral;
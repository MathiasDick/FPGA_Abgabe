library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Essential for math
use work.constants_pkg.all;

entity vga_timing_1080p is
    Port ( clk_pxl  : in  STD_LOGIC; -- 148.5 MHz
           h_sync   : out STD_LOGIC;
           v_sync   : out STD_LOGIC;
           pixel_x  : out STD_LOGIC_VECTOR(11 downto 0);
           pixel_y  : out STD_LOGIC_VECTOR(11 downto 0);
           video_on : out STD_LOGIC);
end vga_timing_1080p;

architecture Behavioral of vga_timing_1080p is

    constant H_FP  : natural := 88;   -- Front Porch
    constant H_PW  : natural := 44;   -- Pulse Width
    constant H_MAX : natural := 2200; -- Total clocks per line
    
    constant V_FP  : natural := 4;    -- Front Porch
    constant V_PW  : natural := 5;    -- Pulse Width
    constant V_MAX : natural := 1125; -- Total lines
    
    constant H_POL : std_logic := '1'; -- Active High
    constant V_POL : std_logic := '1'; -- Active High

    -- COUNTERS (Using natural for easy math)
    signal h_cntr : natural range 0 to H_MAX - 1 := 0;
    signal v_cntr : natural range 0 to V_MAX - 1 := 0;
    
    -- INTERNAL SIGNALS
    signal active : std_logic := '0';

begin

    -------------------------------------------------------
    -- PROCESS: Counters
    -------------------------------------------------------
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

    -------------------------------------------------------
    -- PROCESS: Sync Generation & Output
    -------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            -- 1. Generate Horizontal Sync
            -- Sync starts after Visible Area + Front Porch
            if (h_cntr >= (FRAME_WIDTH + H_FP)) and (h_cntr < (FRAME_WIDTH + H_FP + H_PW)) then
                h_sync <= H_POL;
            else
                h_sync <= not H_POL;
            end if;

            -- 2. Generate Vertical Sync
            if (v_cntr >= (FRAME_HEIGHT + V_FP)) and (v_cntr < (FRAME_HEIGHT + V_FP + V_PW)) then
                v_sync <= V_POL;
            else
                v_sync <= not V_POL;
            end if;
            
            -- 3. Video Active (Visible Area)
            if (h_cntr < FRAME_WIDTH) and (v_cntr < FRAME_HEIGHT) then
                active <= '1';
            else
                active <= '0';
            end if;
            
            -- 4. Drive Outputs
            video_on <= active;
            
            -- Convert integers to STD_LOGIC_VECTOR for the output ports
            pixel_x  <= std_logic_vector(to_unsigned(h_cntr, 12));
            pixel_y  <= std_logic_vector(to_unsigned(v_cntr, 12));
        end if;
    end process;

end Behavioral;
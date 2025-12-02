----------------------------------------------------------------------------------
-- Graphics Renderer
-- 
-- DESCRIPTION:
-- Renders all visual elements of the Pong game including:
-- - Ball and paddles with hit-box detection
-- - Score display using bitmap font ROM
-- - Lives indicator
-- - Welcome screen and Game Over text
-- - State-dependent background colors
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity draw is
    Port ( clk_pxl  : in  STD_LOGIC;
           video_on : in  STD_LOGIC;
           pixel_x  : in  STD_LOGIC_VECTOR(11 downto 0);
           pixel_y  : in  STD_LOGIC_VECTOR(11 downto 0);
           
           -- Object Inputs from Game Logic
           ball_x     : in integer range 0 to 4095;
           ball_y     : in integer range 0 to 4095;
           pad_l_y    : in integer range 0 to 4095;
           pad_r_y    : in integer range 0 to 4095;
           score_l  : in  integer;
           score_r  : in  integer;
           lives    : in  integer;
           
           -- Current game state for background color
           game_state : in state_type; 

           -- RGB Output
           vga_r    : out STD_LOGIC_VECTOR(3 downto 0);
           vga_b    : out STD_LOGIC_VECTOR(3 downto 0);
           vga_g    : out STD_LOGIC_VECTOR(3 downto 0));
end draw;

architecture Behavioral of draw is

    -------------------------------------------------------------------------
    -- CONSTANTS: Score Display Configuration
    -------------------------------------------------------------------------
    constant SCORE_SCALE : natural := 8;         -- Scaling factor for score digits
    constant SCORE_ZONE_TOP : natural := 50;     -- Upper Y boundary of score area
    constant SCORE_ZONE_BOTTOM : natural := 114; -- Lower Y boundary of score area
    constant LEFT_X_BORDER_L : natural := 300;   -- Left score left X boundary
    constant LEFT_X_BORDER_R : natural := 364;   -- Left score right X boundary
    constant RIGHT_X_BORDER_L : natural := 1500; -- Right score left X boundary
    constant RIGHT_X_BORDER_R : natural := 1564; -- Right score right X boundary    
    
    -------------------------------------------------------------------------
    -- CONSTANTS: Welcome Screen Text Configuration
    -------------------------------------------------------------------------
    constant CHAR_WIDTH  : natural := 32;        -- Width of each character in pixels
    constant LETTERS     : natural := 7;         -- Number of letters in "WELCOME"
    constant WORD_WIDTH  : natural := CHAR_WIDTH * LETTERS; -- Total width of "WELCOME" text
    constant WELCOME_X : natural := (FRAME_WIDTH - WORD_WIDTH) / 2; -- Centered X position for "WELCOME"
    constant LETTERS_UPPER_Y_BORDER : natural := 400; -- Upper Y boundary for text rendering
    constant LETTERS_LOWER_Y_BORDER : natural := 432; -- Lower Y boundary for text rendering
    constant COORD_BITS : natural := 12;         -- Bit width of pixel coordinates
    constant WELCOME_MAX_POS : natural := 6;     -- Maximum character position (0-6 for 7 chars)
    constant FONT_MAX_COL : natural := 7;        -- Maximum column index in font bitmap
    constant TEXT_SCALE : natural := 4;          -- Scaling factor for text size
    
    -------------------------------------------------------------------------
    -- CONSTANTS: Game Over Screen Configuration
    -------------------------------------------------------------------------
    constant GO_LETTERS : natural := 9;          -- Number of characters in "GAME OVER" (with space)
    constant GO_WIDTH : natural := CHAR_WIDTH * GO_LETTERS; -- Total width of "GAME OVER" text
    constant GO_X : natural := (FRAME_WIDTH - GO_WIDTH) / 2; -- Centered X position for "GAME OVER"
    constant GO_MAX_POS : natural := 8;          -- Maximum character position (0-8 for 9 chars)
    
    
    -------------------------------------------------------------------------
    -- CONSTANTS: Lives Display Configuration
    -------------------------------------------------------------------------
    constant L_SIZE    : integer := 20;          -- Size of each life indicator square (20x20 pixels)
    constant L_Y_START : integer := 57;          -- Y position for lives display at top of screen
    constant L_GAP     : integer := 25;          -- Horizontal spacing between life indicators
    constant L_X_START : integer := (FRAME_WIDTH - ((2 * L_GAP) + L_SIZE)) / 2; -- Centered X start position

    -------------------------------------------------------------------------
    -- FONT ROM: Character Bitmap Definitions
    -------------------------------------------------------------------------
    type char_bitmap_type is array (0 to 7) of std_logic_vector(7 downto 0);
    type font_rom_type is array (0 to 15) of char_bitmap_type;

    constant FONT_ROM : font_rom_type := (
        0 =>   ("00111100", 
                "01100110", 
                "01100110", 
                "01100110", 
                "01100110", 
                "01100110", 
                "00111100", 
                "00000000"), -- 0
                
        1 =>   ("00011000", 
                "00111000", 
                "00011000", 
                "00011000", 
                "00011000", 
                "00011000", 
                "00111110", 
                "00000000"), -- 1
                
        2 =>   ("00111100", 
                "01100110", 
                "00000110", 
                "00001100", 
                "00110000", 
                "01100000", 
                "01111110", 
                "00000000"), -- 2
                
        3 =>   ("00111100", 
                "01100110", 
                "00000110", 
                "00011100", 
                "00000110", 
                "01100110", 
                "00111100", 
                "00000000"), -- 3
                
        4 =>  ("11000110", 
               "11000110", 
               "11000110", 
               "11010110", 
               "11111110", 
               "11101110", 
               "11000110", 
               "00000000"), -- W
                
        5 =>  ("11111110", 
               "11000000", 
               "11000000", 
               "11111100", 
               "11000000", 
               "11000000", 
               "11111110", 
               "00000000"), -- E
                
        6 =>  ("11000000", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11111110", 
               "00000000"), -- L
                
        7 =>  ("01111110", 
               "11000010", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11000010", 
               "01111110", 
               "00000000"), -- C
                
        8 =>  ("01111100", 
               "11000110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "01111100", 
               "00000000"), -- O
                
        9 =>  ("11000110", 
               "11101110", 
               "11111110", 
               "11010110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "00000000"), -- M
   
        10 => ("01111110", 
               "11000010", 
               "11000000", 
               "11001110", 
               "11000110", 
               "11000110", 
               "01111110", 
               "00000000"), -- G
    
        11 => ("01111100", 
               "11000110", 
               "11000110", 
               "11111110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "00000000"), -- A
    
        12 => ("11000110", 
               "11000110", 
               "11000110", 
               "01101100", 
               "01101100", 
               "00111000", 
               "00010000", 
               "00000000"), -- V
    
        13 => ("11111100", 
               "11000110", 
               "11000110", 
               "11111100", 
               "11110000", 
               "11011000", 
               "11001110", 
               "00000000"), -- R
                        
        others => (others => (others => '0'))
    );

    -------------------------------------------------------------------------
    -- INTERNAL SIGNALS
    -------------------------------------------------------------------------
    -- Pixel coordinates as integers for easier arithmetic
    signal pix_x, pix_y : integer;

    -- Object visibility flags for priority rendering
    signal draw_ball, draw_pad_l, draw_pad_r, draw_lives : std_logic;
    signal draw_text : std_logic;

begin

    -- Convert pixel coordinates to integers for arithmetic operations
    pix_x <= to_integer(unsigned(pixel_x));
    pix_y <= to_integer(unsigned(pixel_y));


    -------------------------------------------------------------------------
    -- OBJECT GENERATION (Hit Box Logic)
    -------------------------------------------------------------------------
    -- Ball
    draw_ball <= '1' when (pix_x >= ball_x and pix_x < ball_x + BALL_SIZE) and
                          (pix_y >= ball_y and pix_y < ball_y + BALL_SIZE) else '0';
                          
    -- Left Paddle
    draw_pad_l <= '1' when (pix_x >= PADDLE_OFFSET and pix_x < PADDLE_OFFSET + PADDLE_W) and
                           (pix_y >= pad_l_y and pix_y < pad_l_y + PADDLE_H) else '0';

    -- Right Paddle
    draw_pad_r <= '1' when (pix_x >= (FRAME_WIDTH - PADDLE_OFFSET - PADDLE_W) and pix_x < (FRAME_WIDTH - PADDLE_OFFSET)) and
                           (pix_y >= pad_r_y and pix_y < pad_r_y + PADDLE_H) else '0';

    -- Lives display: hit box for all three life indicators
    draw_lives <= '1' when 
        -- Ball 1
        (lives >= 1 and (pix_x >= L_X_START and pix_x < L_X_START + L_SIZE) 
                    and (pix_y >= L_Y_START and pix_y < L_Y_START + L_SIZE)) or
        
        -- Ball 2
        (lives >= 2 and (pix_x >= L_X_START + L_GAP and pix_x < L_X_START + L_GAP + L_SIZE) 
                    and (pix_y >= L_Y_START and pix_y < L_Y_START + L_SIZE)) or

        -- Ball 3
        (lives >= 3 and (pix_x >= L_X_START + L_GAP*2 and pix_x < L_X_START + L_GAP*2 + L_SIZE) 
                    and (pix_y >= L_Y_START and pix_y < L_Y_START + L_SIZE))
    else '0';


    -------------------------------------------------------------------------
    -- Text Rendering Engine: Scores, Welcome Screen, and Game Over
    -- Uses bitmap font ROM to render characters pixel by pixel
    -------------------------------------------------------------------------
    process(pix_x, pix_y, score_l, score_r, game_state)
        variable scaled_y    : integer range 0 to 7;    -- Row within character bitmap
        variable char_col    : integer;                 -- Column within character bitmap
        variable char_idx    : integer range 0 to 15;   -- Index into FONT_ROM
        variable text_active : boolean;                 -- Flag if we're in a text region
        variable welcome_pos : integer;                 -- Character position in string
        variable rel_x       : unsigned(11 downto 0);   -- Relative X position within text
    begin
        -- Default: no text rendering
        draw_text   <= '0';
        scaled_y    := 0;
        char_col    := 0;
        char_idx    := 0;
        text_active := false;
        
        -- A. DRAW LEFT SCORE
        if (pix_y >= SCORE_ZONE_TOP and pix_y < SCORE_ZONE_BOTTOM) and (pix_x >= LEFT_X_BORDER_L and pix_x < LEFT_X_BORDER_R) then
            char_idx    := score_l;
            scaled_y    := (pix_y - SCORE_ZONE_TOP) / SCORE_SCALE;
            char_col    := (pix_x - LEFT_X_BORDER_L) / SCORE_SCALE;
            text_active := true;
            
        -- B. DRAW RIGHT SCORE
        elsif (pix_y >= SCORE_ZONE_TOP and pix_y < SCORE_ZONE_BOTTOM) and (pix_x >= RIGHT_X_BORDER_L and pix_x < RIGHT_X_BORDER_R) then
            char_idx    := score_r;
            scaled_y    := (pix_y - SCORE_ZONE_TOP) / SCORE_SCALE;
            char_col    := (pix_x - RIGHT_X_BORDER_L) / SCORE_SCALE;
            text_active := true;
            
        -- C. DRAW "WELCOME" TEXT (Only visible in WELCOME state)
        elsif (game_state = WELCOME) and (pix_y >= LETTERS_UPPER_Y_BORDER and pix_y < LETTERS_LOWER_Y_BORDER) then
            if (pix_x >= WELCOME_X and pix_x < WELCOME_X + WORD_WIDTH) then
                
                -- Calculate position within the word
                rel_x := to_unsigned(pix_x - WELCOME_X, COORD_BITS);
                
                -- Determine which character we're in (divide by 32 using bit slice)
                welcome_pos := to_integer(rel_x(11 downto 5)); 
                
                case welcome_pos is
                    when 0 => char_idx := 4; -- W
                    when 1 => char_idx := 5; -- E
                    when 2 => char_idx := 6; -- L
                    when 3 => char_idx := 7; -- C
                    when 4 => char_idx := 8; -- O
                    when 5 => char_idx := 9; -- M
                    when 6 => char_idx := 5; -- E
                    when others => text_active := false;
                end case;

                if welcome_pos <= WELCOME_MAX_POS then
                    scaled_y := (pix_y - LETTERS_UPPER_Y_BORDER) / TEXT_SCALE;
                    
                    -- Calculate column within character (bits 4..2 = (val mod 32) / 4)
                    char_col := to_integer(rel_x(4 downto 2));
                    
                    text_active := (char_col <= FONT_MAX_COL); 
                end if;
            end if;

        -- D. DRAW "GAME OVER" TEXT (Only visible in GAMEOVER state)
        elsif (game_state = GAMEOVER) and (pix_y >= LETTERS_UPPER_Y_BORDER and pix_y < LETTERS_LOWER_Y_BORDER) then
            if (pix_x >= GO_X and pix_x < GO_X + GO_WIDTH) then
                
                -- Calculate position within the text
                rel_x := to_unsigned(pix_x - GO_X, COORD_BITS);
                
                -- Determine which character we're in
                welcome_pos := to_integer(rel_x(11 downto 5)); 

                case welcome_pos is
                    when 0 => char_idx := 10; -- G
                    when 1 => char_idx := 11; -- A
                    when 2 => char_idx := 9;  -- M
                    when 3 => char_idx := 5;  -- E
                    when 4 => char_idx := 14; -- SPACE
                    when 5 => char_idx := 8;  -- O
                    when 6 => char_idx := 12; -- V
                    when 7 => char_idx := 5;  -- E
                    when 8 => char_idx := 13; -- R
                    when others => text_active := false;
                end case;

                if welcome_pos <= GO_MAX_POS then
                    scaled_y := (pix_y - LETTERS_UPPER_Y_BORDER) / TEXT_SCALE;
                    
                    -- Calculate column within character
                    char_col := to_integer(rel_x(4 downto 2));
                    
                    text_active := (char_col <= FONT_MAX_COL); 
                end if;
            end if;
        end if;
        
        -- E. RENDER PIXEL FROM FONT ROM
        -- Check if the current pixel should be lit based on the character bitmap
        if text_active and (char_col >= 0 and char_col <= FONT_MAX_COL) then
            if FONT_ROM(char_idx)(scaled_y)(FONT_MAX_COL - char_col) = '1' then
                draw_text <= '1';
            end if;
        end if;
        
    end process;

    -------------------------------------------------------------------------
    -- Color Multiplexer: Priority-Based Rendering
    -- Determines final RGB output based on which objects are visible
    -------------------------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            -- Default: Black when video is off
            if video_on = '0' then
                vga_r <= "0000";
                vga_g <= "0000"; 
                vga_b <= "0000";
            else
                -- Priority 1: Text (White)
                if draw_text = '1' then
                    vga_r <= "1111";
                    vga_g <= "1111"; 
                    vga_b <= "1111";
                    
                -- Priority 2: Ball (White)
                elsif draw_ball = '1' then
                    vga_r <= "1111";
                    vga_g <= "1111"; 
                    vga_b <= "1111";

                -- Priority 3: Left Paddle (Cyan)
                elsif draw_pad_l = '1' then
                    vga_r <= "0000";
                    vga_g <= "1111"; 
                    vga_b <= "1111";

                -- Priority 4: Right Paddle (Magenta)
                elsif draw_pad_r = '1' then
                    vga_r <= "1111";
                    vga_g <= "0000"; 
                    vga_b <= "1111";

                -- Priority 5: Lives indicator (Orange-red)
                elsif draw_lives = '1' then
                    vga_r <= "1111";
                    vga_g <= "0100"; 
                    vga_b <= "0100"; 
                    
                -- Priority 6: Background (State-dependent color)
                else
                    case game_state is
                        when WELCOME =>
                            vga_r <= "0000";
                            vga_g <= "0000"; 
                            vga_b <= "0011"; -- Blue
                        when GAMEOVER =>
                            vga_r <= "0011";
                            vga_g <= "0000"; 
                            vga_b <= "0000"; -- Dark red
                        when others =>
                            vga_r <= "0000";
                            vga_g <= "0000"; 
                            vga_b <= "0000"; -- Black (PLAY/SERVE)
                    end case;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
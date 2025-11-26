library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Required for coordinate math
use work.constants_pkg.all;

entity draw is
    Port ( clk_pxl  : in  STD_LOGIC;
           video_on : in  STD_LOGIC;
           pixel_x  : in  STD_LOGIC_VECTOR(11 downto 0);
           pixel_y  : in  STD_LOGIC_VECTOR(11 downto 0);
           
           -- Object Inputs from Game Logic
           ball_x   : in  STD_LOGIC_VECTOR(11 downto 0);
           ball_y   : in  STD_LOGIC_VECTOR(11 downto 0);
           pad_l_y  : in  STD_LOGIC_VECTOR(11 downto 0);
           pad_r_y  : in  STD_LOGIC_VECTOR(11 downto 0);
           score_l  : in  integer;
           score_r  : in  integer;
           lives    : in  integer;
           
           -- NEW: We need to know the state to change background color!
           -- 0=WELCOME, 1=PLAY/SERVE, 2=GAMEOVER
           game_state : in state_type; 

           -- RGB Output
           vga_r    : out STD_LOGIC_VECTOR(3 downto 0);
           vga_b    : out STD_LOGIC_VECTOR(3 downto 0);
           vga_g    : out STD_LOGIC_VECTOR(3 downto 0));
end draw;

architecture Behavioral of draw is

    -- "Welcome" Values
    constant CHAR_WIDTH  : natural := 32;
    constant LETTERS     : natural := 7;
    constant WORD_WIDTH  : natural := CHAR_WIDTH * LETTERS;
    
    -- "Game Over" Values
    constant GO_LETTERS  : natural := 9; -- "GAME OVER" is 9 chars (including space)
    constant GO_WIDTH    : natural := CHAR_WIDTH * GO_LETTERS;
    constant GO_X        : natural := (FRAME_WIDTH - GO_WIDTH) / 2;
    
    constant WELCOME_X : natural := (FRAME_WIDTH - WORD_WIDTH) / 2;
    
    constant L_SIZE    : integer := 20;  -- 16x16 pixel squares
    constant L_Y_START : integer := 57;  -- Vertical Position
    constant L_GAP     : integer := 25;  -- Distance between balls
    
    constant L_X_START   : integer := (FRAME_WIDTH - ((2 * L_GAP) + L_SIZE)) / 2;


    -- 1. DEFINE FONT TYPES AND CONSTANTS (The "Visual" Bitmap)
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
                "00000000"),
                
        1 =>   ("00011000", 
                "00111000", 
                "00011000", 
                "00011000", 
                "00011000", 
                "00011000", 
                "00111110", 
                "00000000"),
                
        2 =>   ("00111100", 
                "01100110", 
                "00000110", 
                "00001100", 
                "00110000", 
                "01100000", 
                "01111110", 
                "00000000"),
                
        3 =>   ("00111100", 
                "01100110", 
                "00000110", 
                "00011100", 
                "00000110", 
                "01100110", 
                "00111100", 
                "00000000"),
                
        4 =>  ("11000110", 
               "11000110", 
               "11000110", 
               "11010110", 
               "11111110", 
               "11101110", 
               "11000110", 
               "00000000"), --W
                
        5 =>  ("11111110", 
               "11000000", 
               "11000000", 
               "11111100", 
               "11000000", 
               "11000000", 
               "11111110", 
               "00000000"), --E
                
        6 =>  ("11000000", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11111110", 
               "00000000"), --L
                
        7 =>  ("01111110", 
               "11000010", 
               "11000000", 
               "11000000", 
               "11000000", 
               "11000010", 
               "01111110", 
               "00000000"), --C
                
        8 =>  ("01111100", 
               "11000110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "01111100", 
               "00000000"), --O
                
        9 =>  ("11000110", 
               "11101110", 
               "11111110", 
               "11010110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "00000000"), --M
   
        10 => ("01111110", 
               "11000010", 
               "11000000", 
               "11001110", 
               "11000110", 
               "11000110", 
               "01111110", 
               "00000000"), --G
    
        11 => ("01111100", 
               "11000110", 
               "11000110", 
               "11111110", 
               "11000110", 
               "11000110", 
               "11000110", 
               "00000000"), --A
    
        12 => ("11000110", 
               "11000110", 
               "11000110", 
               "01101100", 
               "01101100", 
               "00111000", 
               "00010000", 
               "00000000"), --V
    
        13 => ("11111100", 
               "11000110", 
               "11000110", 
               "11111100", 
               "11110000", 
               "11011000", 
               "11001110", 
               "00000000"), --R
                        
        others => (others => (others => '0'))
    );

    -- INTERNAL SIGNALS
    signal pix_x, pix_y : integer;
    signal b_x, b_y     : integer;
    signal pl_y, pr_y   : integer;

    -- DRAW FLAGS
    signal draw_ball, draw_pad_l, draw_pad_r, draw_lives : std_logic;
    signal draw_text : std_logic;

begin

    -- 1. CONVERT INPUTS TO INTEGERS
    pix_x <= to_integer(unsigned(pixel_x));
    pix_y <= to_integer(unsigned(pixel_y));
    b_x   <= to_integer(unsigned(ball_x));
    b_y   <= to_integer(unsigned(ball_y));
    pl_y  <= to_integer(unsigned(pad_l_y));
    pr_y  <= to_integer(unsigned(pad_r_y));

    -------------------------------------------------------------------------
    -- 2. OBJECT GENERATION (Hit Box Logic)
    -------------------------------------------------------------------------
    -- Ball
    draw_ball <= '1' when (pix_x >= b_x and pix_x < b_x + BALL_SIZE) and
                          (pix_y >= b_y and pix_y < b_y + BALL_SIZE) else '0';
                          
    -- Left Paddle
    draw_pad_l <= '1' when (pix_x >= PADDLE_OFFSET and pix_x < PADDLE_OFFSET + PADDLE_W) and
                           (pix_y >= pl_y and pix_y < pl_y + PADDLE_H) else '0';

    -- Right Paddle
    draw_pad_r <= '1' when (pix_x >= (FRAME_WIDTH - PADDLE_OFFSET - PADDLE_W) and pix_x < (FRAME_WIDTH - PADDLE_OFFSET)) and
                           (pix_y >= pr_y and pix_y < pr_y + PADDLE_H) else '0';

    -- Live Balls
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
    -- 3. TEXT ENGINE (Scores & Welcome)
    -------------------------------------------------------------------------
    process(pix_x, pix_y, score_l, score_r, game_state)
        variable scaled_y    : integer range 0 to 7;
        variable char_col    : integer;
        variable char_idx    : integer range 0 to 15;
        variable text_active : boolean;
        variable welcome_pos : integer;
        variable rel_x       : unsigned(11 downto 0);
    begin
        -- Defaults
        draw_text   <= '0';
        scaled_y    := 0;
        char_col    := 0;
        char_idx    := 0;
        text_active := false;
        
        -- A. DRAW LEFT SCORE
        if (pix_y >= 50 and pix_y < 114) and (pix_x >= 300 and pix_x < 364) then
            char_idx    := score_l;
            scaled_y    := (pix_y - 50) / 8;
            char_col    := (pix_x - 300) / 8;
            text_active := true;
            
        -- B. DRAW RIGHT SCORE
        elsif (pix_y >= 50 and pix_y < 114) and (pix_x >= 1500 and pix_x < 1564) then
            char_idx    := score_r;
            scaled_y    := (pix_y - 50) / 8;
            char_col    := (pix_x - 1500) / 8;
            text_active := true;
            
-- C. DRAW "WELCOME" (Only in WELCOME)
        elsif (game_state = WELCOME) and (pix_y >= 400 and pix_y < 432) then
            if (pix_x >= WELCOME_X and pix_x < WELCOME_X + WORD_WIDTH) then
                
                -- 1. Calculate Relative X (Distance from start of word)
                rel_x := to_unsigned(pix_x - WELCOME_X, 12);
                
                -- 2. Bit Slice for Index: Dividing by 32 means looking at bits 5 and up
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

                if welcome_pos <= 6 then
                    scaled_y := (pix_y - 400) / 4;
                    
                    -- 3. Bit Slice for Column: Bits 4..2 represent (val % 32) / 4
                    char_col := to_integer(rel_x(4 downto 2));
                    
                    text_active := (char_col < 8); 
                end if;
            end if;

        -- D. DRAW "GAME OVER" (Only in GAMEOVER state)
        elsif (game_state = GAMEOVER) and (pix_y >= 400 and pix_y < 432) then
            if (pix_x >= GO_X and pix_x < GO_X + GO_WIDTH) then
                
                -- 1. Calculate Relative X
                rel_x := to_unsigned(pix_x - GO_X, 12);
                
                -- 2. Bit Slice for Index
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

                if welcome_pos <= 8 then
                    scaled_y := (pix_y - 400) / 4;
                    
                    -- 3. Bit Slice for Column
                    char_col := to_integer(rel_x(4 downto 2));
                    
                    text_active := (char_col < 8); 
                end if;
            end if;
        end if;
        
        
        -- D. RENDER PIXEL FROM ROM
        if text_active and (char_col >= 0 and char_col <= 7) then
            -- Check the bit in the constant array
            if FONT_ROM(char_idx)(scaled_y)(7 - char_col) = '1' then
                draw_text <= '1';
            end if;
        end if;
        
    end process;

    -------------------------------------------------------------------------
    -- 4. COLOR MUX (PRIORITY ENCODER)
    -------------------------------------------------------------------------
    process (video_on, draw_text, draw_ball, draw_pad_l, draw_pad_r, draw_lives, game_state)
    begin
        if video_on = '0' then
            vga_r <= C_BLACK; vga_g <= C_BLACK; vga_b <= C_BLACK;
        else
            -- Priority 1: Text (White)
            if draw_text = '1' then
                vga_r <= C_WHITE; vga_g <= C_WHITE; vga_b <= C_WHITE;
                
            -- Priority 2: Ball (White)
            elsif draw_ball = '1' then
                vga_r <= C_WHITE; vga_g <= C_WHITE; vga_b <= C_WHITE;

            -- Priority 3: Left Paddle (Cyan)
            elsif draw_pad_l = '1' then
                vga_r <= "0000"; vga_g <= C_GREEN; vga_b <= C_BLUE; 

            -- Priority 4: Right Paddle (Magenta)
            elsif draw_pad_r = '1' then
                vga_r <= C_RED; vga_g <= "0000"; vga_b <= C_BLUE; 

            -- Priority 5: Life Bar (Green)
            elsif draw_lives = '1' then
                vga_r <= "1111"; vga_g <= "0100"; vga_b <= "0100"; 
                
            -- Priority 6: Background (Depends on State)
            else
                case game_state is
                    when WELCOME => -- WELCOME (Blue)
                        vga_r <= "0000"; vga_g <= "0000"; vga_b <= "0011";
                    when GAMEOVER => -- GAMEOVER (Red)
                        vga_r <= "0011"; vga_g <= "0000"; vga_b <= "0000";
                    when others => -- PLAY/SERVE (Black)
                        vga_r <= C_BLACK; vga_g <= C_BLACK; vga_b <= C_BLACK;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
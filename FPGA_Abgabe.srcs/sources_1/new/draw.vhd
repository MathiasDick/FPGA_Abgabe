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
           -- 0=IDLE, 1=PLAY/SERVE, 2=GAMEOVER
           game_state : in state_type; 

           -- RGB Output
           vga_r    : out STD_LOGIC_VECTOR(3 downto 0);
           vga_b    : out STD_LOGIC_VECTOR(3 downto 0);
           vga_g    : out STD_LOGIC_VECTOR(3 downto 0));
end draw;

architecture Behavioral of draw is

    -- INTERNAL SIGNALS (Integer versions of inputs for easier math)
    signal pix_x, pix_y : integer;
    signal b_x, b_y     : integer;
    signal pl_y, pr_y   : integer;

    -- DRAW FLAGS (True if pixel is inside object)
    signal draw_ball, draw_pad_l, draw_pad_r, draw_lives : std_logic;
    signal draw_text : std_logic;

    -- TEXT ENGINE SIGNALS
    signal char_selection : integer range 0 to 15 := 0; 
    signal char_line_bits : std_logic_vector(7 downto 0); 

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

    -- Life Bar (Green bar at top)
    draw_lives <= '1' when (pix_y > 50 and pix_y < 80) and
                           (pix_x > 900 and pix_x < 900 + (lives * 50)) else '0';


    -------------------------------------------------------------------------
    -- 3. TEXT ENGINE (Scores & Welcome)
    -------------------------------------------------------------------------
    process(pix_x, pix_y, score_l, score_r, game_state, char_selection)
        variable scaled_y : integer;
        variable char_col_idx : integer;
    begin
        draw_text <= '0';
        char_selection <= 0; 
        scaled_y := 0;
        char_col_idx := -1;
        
        -- A. DRAW LEFT SCORE
        if (pix_y >= 50 and pix_y < 114) and (pix_x >= 300 and pix_x < 364) then
            char_selection <= score_l;
            scaled_y := (pix_y - 50) / 8; -- Scale 8x
            char_col_idx := (pix_x - 300) / 8; 
            
        -- B. DRAW RIGHT SCORE
        elsif (pix_y >= 50 and pix_y < 114) and (pix_x >= 1500 and pix_x < 1564) then
            char_selection <= score_r;
            scaled_y := (pix_y - 50) / 8;
            char_col_idx := (pix_x - 1500) / 8;
            
        -- C. DRAW "WELCOME" (Only in IDLE state: game_state = 0)
        elsif (game_state = IDLE) and (pix_y >= 400 and pix_y < 432) then
            scaled_y := (pix_y - 400) / 4; -- Scale 4x
            
            if (pix_x >= 800 and pix_x < 832) then char_selection <= 10; -- W
                char_col_idx := (pix_x - 800) / 4;
            elsif (pix_x >= 840 and pix_x < 872) then char_selection <= 11; -- E
                char_col_idx := (pix_x - 840) / 4;
            elsif (pix_x >= 880 and pix_x < 912) then char_selection <= 12; -- L
                char_col_idx := (pix_x - 880) / 4;
            elsif (pix_x >= 920 and pix_x < 952) then char_selection <= 13; -- C
                char_col_idx := (pix_x - 920) / 4;
            elsif (pix_x >= 960 and pix_x < 992) then char_selection <= 14; -- O
                char_col_idx := (pix_x - 960) / 4;
            elsif (pix_x >= 1000 and pix_x < 1032) then char_selection <= 15; -- M
                char_col_idx := (pix_x - 1000) / 4;
            elsif (pix_x >= 1040 and pix_x < 1072) then char_selection <= 11; -- E
                char_col_idx := (pix_x - 1040) / 4;
            end if;
        end if;
        
        -- D. BITMAP DEFINITIONS
        case char_selection is
            when 0 => case scaled_y is when 0|6 => char_line_bits <= "00111100"; when 1 to 5 => char_line_bits <= "01100110"; when others => char_line_bits <= "00000000"; end case;
            when 1 => case scaled_y is when 0|2 to 5 => char_line_bits <= "00011000"; when 1 => char_line_bits <= "00111000"; when 6 => char_line_bits <= "00111110"; when others => char_line_bits <= "00000000"; end case;
            when 2 => case scaled_y is when 0 => char_line_bits <= "00111100"; when 1 => char_line_bits <= "01100110"; when 2 => char_line_bits <= "00000110"; when 3 => char_line_bits <= "00001100"; when 4 => char_line_bits <= "00110000"; when 5 => char_line_bits <= "01100000"; when 6 => char_line_bits <= "01111110"; when others => char_line_bits <= "00000000"; end case;
            when 3 => case scaled_y is when 0|6 => char_line_bits <= "00111100"; when 1|5 => char_line_bits <= "01100110"; when 2|4 => char_line_bits <= "00000110"; when 3 => char_line_bits <= "00011100"; when others => char_line_bits <= "00000000"; end case;
            when 4 => case scaled_y is when 0 => char_line_bits <= "00001100"; when 1 => char_line_bits <= "00011100"; when 2 => char_line_bits <= "00101100"; when 3 => char_line_bits <= "01001100"; when 4 => char_line_bits <= "01111110"; when 5|6 => char_line_bits <= "00001100"; when others => char_line_bits <= "00000000"; end case;
            when 5 => case scaled_y is when 0 => char_line_bits <= "01111110"; when 1 => char_line_bits <= "01100000"; when 2 => char_line_bits <= "01111100"; when 3|4 => char_line_bits <= "00000110"; when 5 => char_line_bits <= "01100110"; when 6 => char_line_bits <= "00111100"; when others => char_line_bits <= "00000000"; end case;
            when 6 => case scaled_y is when 0 => char_line_bits <= "00111100"; when 1 => char_line_bits <= "01100110"; when 2 => char_line_bits <= "01100000"; when 3 => char_line_bits <= "01111100"; when 4|5 => char_line_bits <= "01100110"; when 6 => char_line_bits <= "00111100"; when others => char_line_bits <= "00000000"; end case;
            when 7 => case scaled_y is when 0 => char_line_bits <= "01111110"; when 1 => char_line_bits <= "00000110"; when 2 => char_line_bits <= "00001100"; when 3 => char_line_bits <= "00011000"; when 4 to 6 => char_line_bits <= "00110000"; when others => char_line_bits <= "00000000"; end case;
            when 8 => case scaled_y is when 0|3|6 => char_line_bits <= "00111100"; when 1|2|4|5 => char_line_bits <= "01100110"; when others => char_line_bits <= "00000000"; end case;
            when 9 => case scaled_y is when 0|6 => char_line_bits <= "00111100"; when 1|2 => char_line_bits <= "01100110"; when 3 => char_line_bits <= "00111110"; when 4|5 => char_line_bits <= "00000110"; when others => char_line_bits <= "00000000"; end case;
            when 10 => -- W
                 case scaled_y is when 0 to 2 => char_line_bits <= "11000011"; when 3 => char_line_bits <= "11011011"; when 4 => char_line_bits <= "11111111"; when 5 => char_line_bits <= "10100101"; when 6 => char_line_bits <= "10000001"; when others => char_line_bits <= "00000000"; end case;
            when 11 => -- E
                 case scaled_y is when 0|6 => char_line_bits <= "11111110"; when 1|2|4|5 => char_line_bits <= "11000000"; when 3 => char_line_bits <= "11111000"; when others => char_line_bits <= "00000000"; end case;
            when 12 => -- L
                 case scaled_y is when 0 to 5 => char_line_bits <= "11000000"; when 6 => char_line_bits <= "11111110"; when others => char_line_bits <= "00000000"; end case;
            when 13 => -- C
                 case scaled_y is when 0|6 => char_line_bits <= "00111100"; when 1|5 => char_line_bits <= "01100000"; when 2 to 4 => char_line_bits <= "11000000"; when others => char_line_bits <= "00000000"; end case;
            when 14 => -- O
                 case scaled_y is when 0|6 => char_line_bits <= "00111100"; when 1 to 5 => char_line_bits <= "01100110"; when others => char_line_bits <= "00000000"; end case;
            when 15 => -- M
                 case scaled_y is when 0|5|6 => char_line_bits <= "10000001"; when 1 => char_line_bits <= "11000011"; when 2 => char_line_bits <= "11100111"; when 3 => char_line_bits <= "10111101"; when 4 => char_line_bits <= "10011001"; when others => char_line_bits <= "00000000"; end case;
            when others => char_line_bits <= "00000000";
        end case;

        -- E. CHECK BIT
        if (char_col_idx >= 0 and char_col_idx <= 7) then
            if char_line_bits(7 - char_col_idx) = '1' then 
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
                vga_r <= "0000"; vga_g <= C_GREEN; vga_b <= "0000"; 
                
            -- Priority 6: Background (Depends on State)
            else
                case game_state is
                    when IDLE => -- IDLE (Blue)
                        vga_r <= "0000"; vga_g <= "0000"; vga_b <= C_BLUE;
                    when GAMEOVER => -- GAMEOVER (Red)
                        vga_r <= C_RED; vga_g <= "0000"; vga_b <= "0000";
                    when others => -- PLAY/SERVE (Black)
                        vga_r <= C_BLACK; vga_g <= C_BLACK; vga_b <= C_BLACK;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
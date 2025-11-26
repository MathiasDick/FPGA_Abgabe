library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Essential for math
use work.constants_pkg.all; -- Imports constants and state_type

entity game_logic is
    Port ( clk_pxl   : in  STD_LOGIC;
           rst       : in  STD_LOGIC; -- Mapped to sw(0) in top
           LEFT_P_UP : in STD_LOGIC;
           LEFT_P_DOWN : in STD_LOGIC;
           RIGHT_P_UP : in STD_LOGIC;
           RIGHT_P_DOWN : in STD_LOGIC;
           
           -- Outputs to the Renderer
           ball_x    : out integer range 0 to 4095;
           ball_y    : out integer range 0 to 4095;
           pad_l_y   : out integer range 0 to 4095;
           pad_r_y   : out integer range 0 to 4095;
           
           score_l   : out integer range 0 to 9;
           score_r   : out integer range 0 to 9;
           lives     : out integer range 0 to 3;
           
           -- We changed this from 'integer' to 'state_type' 
           -- so it plugs directly into the other modules!
           game_state_out : out state_type 
           );
end game_logic;

architecture Behavioral of game_logic is

    -- INTERNAL SIGNALS (Using Integers for easy math)
    -- We track positions as integers internally, then convert to vectors for output
    signal b_x, b_y     : integer range 0 to 4095 := 960; -- Start Center
    signal pl_y, pr_y   : integer range 0 to 4095 := 450; -- Start Center
    
    -- Velocity Directions
    signal b_dx : std_logic := '1'; -- 1=Right, 0=Left
    signal b_dy : std_logic := '1'; -- 1=Down, 0=Up
    
    -- State Machine
    signal state : state_type := WELCOME;
    
    -- Scoring
    signal lives_reg : integer range 0 to 3 := 3;
    signal sc_l, sc_r : integer range 0 to 9 := 0;

    -- Physics Timing
    signal ball_tick    : std_logic;
    signal ball_cntr    : integer range 0 to BALL_CLK_DIV := 0;
    
    signal paddle_tick  : std_logic;
    signal paddle_cntr  : integer range 0 to PADDLE_CLK_DIV := 0;

begin

    -------------------------------------------------------------------------
    -- PROCESS 1: PHYSICS CLOCK GENERATOR (The Heartbeat)
    -------------------------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            -- 1. Ball Timer
            if ball_cntr = (BALL_CLK_DIV - 1) then
                ball_cntr <= 0;
                ball_tick <= '1';
            else
                ball_cntr <= ball_cntr + 1;
                ball_tick <= '0';
            end if;

            -- 2. Paddle Timer
            if paddle_cntr = (PADDLE_CLK_DIV - 1) then
                paddle_cntr <= 0;
                paddle_tick <= '1';
            else
                paddle_cntr <= paddle_cntr + 1;
                paddle_tick <= '0';
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- PROCESS 2: MAIN GAME LOGIC
    -------------------------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            
            -- HARD RESET
            if rst = '1' then
                state <= WELCOME;
                lives_reg <= 3;
                sc_l <= 0; sc_r <= 0;
                b_x <= 960; b_y <= 540;
                pl_y <= 450; pr_y <= 450;
            
            -- PHYSICS UPDATE TICK
            else
                
                case state is
                    ---------------------------------------------------------
                    when WELCOME =>
                        if (LEFT_P_UP /= '0' or LEFT_P_DOWN /= '0' or RIGHT_P_UP /= '0' or RIGHT_P_DOWN /= '0') then state <= SERVE; end if;
                    ---------------------------------------------------------
                    when SERVE =>
                        -- Center Ball
                        b_x <= 960; 
                        b_y <= 540;
                        -- Launch on Up Button
                        if LEFT_P_UP = '1' or LEFT_P_DOWN = '1' or RIGHT_P_UP = '1' or RIGHT_P_DOWN = '1' then state <= PLAY; 
                        end if;
                    when PLAY =>
                        
                        -- === PADDLE MOVEMENT (Runs on Paddle Tick) ===
                        if paddle_tick = '1' then
                            -- Left
                            if LEFT_P_UP = '1' and pl_y > 20 then pl_y <= pl_y - 1; end if;
                            if LEFT_P_DOWN = '1' and pl_y < 900 then pl_y <= pl_y + 1; end if;
                            -- Right
                            if RIGHT_P_UP = '1' and pr_y > 20 then pr_y <= pr_y - 1; end if;
                            if RIGHT_P_DOWN = '1' and pr_y < 900 then pr_y <= pr_y + 1; end if;
                        end if;

                        -- === BALL MOVEMENT & COLLISION (Runs on Ball Tick) ===
                        if ball_tick = '1' then
                            
                            -- A. BALL Y MOVEMENT (Bouncing off top/bottom)
                            if b_dy = '1' then -- Down
                                if b_y >= (FRAME_HEIGHT - BALL_SIZE - 10) then 
                                    b_dy <= '0'; 
                                else 
                                    b_y <= b_y + 1; 
                                end if;
                            else -- Up
                                if b_y <= 10 then 
                                    b_dy <= '1'; 
                                else 
                                    b_y <= b_y - 1; 
                                end if;
                            end if;
                            
                            -- B. BALL X MOVEMENT (Collisions & Scoring)
                            if b_dx = '1' then -- Moving Right
                                -- Hit Right Paddle?
                                if (b_x + BALL_SIZE >= FRAME_WIDTH - PADDLE_OFFSET - PADDLE_W) and
                                   (b_x + BALL_SIZE <= FRAME_WIDTH - PADDLE_OFFSET) and
                                   (b_y + BALL_SIZE >= pr_y) and (b_y <= pr_y + PADDLE_H) then
                                    b_dx <= '0'; -- Bounce
                                -- Missed?
                                elsif b_x >= (FRAME_WIDTH - BALL_SIZE - 5) then
                                    if sc_l < 9 then sc_l <= sc_l + 1; end if;
                                    
                                    if lives_reg = 1 then 
                                        lives_reg <= 0; state <= GAMEOVER; 
                                    else 
                                        lives_reg <= lives_reg - 1; state <= SERVE; 
                                    end if;
                                else
                                    b_x <= b_x + 1; -- Continue
                                end if;
                            else -- Moving Left
                                -- Hit Left Paddle?
                                if (b_x <= PADDLE_OFFSET + PADDLE_W) and (b_x >= PADDLE_OFFSET) and
                                   (b_y + BALL_SIZE >= pl_y) and (b_y <= pl_y + PADDLE_H) then
                                    b_dx <= '1'; -- Bounce
                                -- Missed?
                                elsif b_x <= 5 then
                                    if sc_r < 9 then sc_r <= sc_r + 1; end if;
                                    
                                    if lives_reg = 1 then 
                                        lives_reg <= 0; state <= GAMEOVER; 
                                    else 
                                        lives_reg <= lives_reg - 1; state <= SERVE; 
                                    end if;
                                else
                                    b_x <= b_x - 1; -- Continue
                                end if;
                            end if;
                        end if; -- End Ball Tick

                    ---------------------------------------------------------
                    when GAMEOVER =>
                        -- Wait for Reset (handled in Hard Reset block)
               end case;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- OUTPUT CONVERSIONS
    -------------------------------------------------------------------------
    -- Convert our internal Integers to STD_LOGIC_VECTORS for the ports
    ball_x  <= b_x;
    ball_y  <= b_y;
    pad_l_y <= pl_y;
    pad_r_y <= pr_y;
    
    -- Pass signals directly
    score_l <= sc_l;
    score_r <= sc_r;
    lives   <= lives_reg;
    game_state_out <= state;

end Behavioral;
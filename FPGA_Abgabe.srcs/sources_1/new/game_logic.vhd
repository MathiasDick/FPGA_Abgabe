----------------------------------------------------------------------------------
-- Game Logic Controller
-- 
-- DESCRIPTION:
-- Handles all game physics and state management for Pong.
-- Includes ball movement, paddle control, collision detection,
-- scoring system, and state machine (WELCOME/SERVE/PLAY/GAMEOVER).
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity game_logic is
    Port ( clk_pxl   : in  STD_LOGIC;
           rst       : in  STD_LOGIC;
           LEFT_P_UP : in STD_LOGIC;
           LEFT_P_DOWN : in STD_LOGIC;
           RIGHT_P_UP : in STD_LOGIC;
           RIGHT_P_DOWN : in STD_LOGIC;
           
           -- Outputs to the Renderer
           ball_x    : out integer range 0 to 4095;
           ball_y    : out integer range 0 to 4095;
           pad_l_y   : out integer range 0 to 4095;
           pad_r_y   : out integer range 0 to 4095;
           
           score_l   : out integer range 0 to 3;
           score_r   : out integer range 0 to 3;
           lives     : out integer range 0 to 3;
           
           -- Current game state
           game_state_out : out state_type 
           );
end game_logic;

architecture Behavioral of game_logic is
    
    -------------------------------------------------------------------------
    -- CONSTANTS: Initial Positions
    -------------------------------------------------------------------------
    constant BALL_Y_CENTER : natural := (FRAME_HEIGHT / 2) - (BALL_SIZE / 2);  -- Vertical center position for ball
    constant BALL_X_CENTER : natural := (FRAME_WIDTH / 2) - (BALL_SIZE / 2);   -- Horizontal center position for ball
    constant PADDLE_CENTER : natural := (FRAME_HEIGHT / 2) - (PADDLE_H / 2);   -- Vertical center position for paddles
    
    -------------------------------------------------------------------------
    -- CONSTANTS: Movement Boundaries
    -------------------------------------------------------------------------
    constant EDGE_BUFFER : natural := 20;   -- Distance from screen edges for paddle limits
    
    constant PADDLE_TOP_LIMIT : natural := EDGE_BUFFER;   -- Upper limit for paddle movement
    constant PADDLE_BOTTOM_LIMIT : natural := FRAME_HEIGHT - PADDLE_H - EDGE_BUFFER;   -- Lower limit for paddle movement
    
    constant SPACE_TO_FRAME : natural := 10;        -- Ball bounce distance from frame edge
    constant SAFETY_MARGIN : natural := 5;          -- Margin for scoring detection
    
    -------------------------------------------------------------------------
    -- INTERNAL SIGNALS
    -------------------------------------------------------------------------
    -- Object positions
    signal b_x, b_y     : integer range 0 to 4095 := BALL_X_CENTER;  -- Ball position
    signal pl_y, pr_y   : integer range 0 to 4095 := PADDLE_CENTER;  -- Paddle positions
    
    -- Ball velocity direction flags
    signal b_dx : std_logic := '1';  -- Horizontal: 1=Right, 0=Left
    signal b_dy : std_logic := '1';  -- Vertical: 1=Down, 0=Up
    
    -- State Machine
    signal state : state_type := WELCOME;
    
    -- Scoring
    signal lives_reg : integer range 0 to 3 := 3;
    signal sc_l, sc_r : integer range 0 to 3 := 0;

    -- Clock divider signals for physics timing
    signal ball_tick    : std_logic;
    signal ball_cntr    : integer range 0 to BALL_CLK_DIV := 0;
    
    signal paddle_tick  : std_logic;
    signal paddle_cntr  : integer range 0 to PADDLE_CLK_DIV := 0;

begin

    -------------------------------------------------------------------------
    -- PROCESS 1: Physics Clock Generator
    -- Generates timing ticks for ball and paddle movement
    -------------------------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            -- Ball movement timer
            if ball_cntr = (BALL_CLK_DIV - 1) then
                ball_cntr <= 0;
                ball_tick <= '1';
            else
                ball_cntr <= ball_cntr + 1;
                ball_tick <= '0';
            end if;

            -- Paddle movement timer
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
    -- PROCESS 2: Main Game Logic
    -- Handles state machine, ball physics, paddle control, and scoring
    -------------------------------------------------------------------------
    process (clk_pxl)
    begin
        if rising_edge(clk_pxl) then
            
            -- Reset to initial state
            if rst = '1' then
                state <= WELCOME;
                lives_reg <= MAX_LIVES;
                sc_l <= 0; sc_r <= 0;
                b_x <= BALL_X_CENTER; b_y <= BALL_Y_CENTER;
                pl_y <= PADDLE_CENTER; pr_y <= PADDLE_CENTER;
            
            else
                
                case state is
                    
                    when WELCOME =>
                        -- Center the ball and paddles
                        b_x <= BALL_X_CENTER; 
                        b_y <= BALL_Y_CENTER;
                        pl_y <= PADDLE_CENTER;
                        pr_y <= PADDLE_CENTER;
                        
                        -- Wait for any button press to start
                        if (LEFT_P_UP = '1' or LEFT_P_DOWN = '1' or RIGHT_P_UP = '1' or RIGHT_P_DOWN = '1') then 
                            state <= SERVE; 
                        end if;
                    
                    when SERVE =>
                        -- Center the ball
                        b_x <= BALL_X_CENTER; 
                        b_y <= BALL_Y_CENTER;
                        -- Launch ball when any button is pressed
                        if LEFT_P_UP = '1' or LEFT_P_DOWN = '1' or RIGHT_P_UP = '1' or RIGHT_P_DOWN = '1' then 
                            state <= PLAY; 
                        end if;
                    
                    when PLAY =>
                        
                        -- Paddle movement (controlled by paddle_tick)
                        if paddle_tick = '1' then
                            -- Left paddle
                            if LEFT_P_UP = '1' and pl_y > PADDLE_TOP_LIMIT then 
                                pl_y <= pl_y - 1; 
                            end if;
                            if LEFT_P_DOWN = '1' and pl_y < PADDLE_BOTTOM_LIMIT then 
                                pl_y <= pl_y + 1; 
                            end if;
                            -- Right paddle
                            if RIGHT_P_UP = '1' and pr_y > PADDLE_TOP_LIMIT then 
                                pr_y <= pr_y - 1; 
                            end if;
                            if RIGHT_P_DOWN = '1' and pr_y < PADDLE_BOTTOM_LIMIT then 
                                pr_y <= pr_y + 1; 
                            end if;
                        end if;

                        -- Ball movement and collision detection (controlled by ball_tick)
                        if ball_tick = '1' then
                            
                            -- Vertical movement and wall bouncing
                            if b_dy = '1' then  -- Moving down
                                if b_y >= (FRAME_HEIGHT - BALL_SIZE - SPACE_TO_FRAME) then 
                                    b_dy <= '0';  -- Bounce up
                                else 
                                    b_y <= b_y + 1; 
                                end if;
                            else  -- Moving up
                                if b_y <= SPACE_TO_FRAME then 
                                    b_dy <= '1';  -- Bounce down
                                else 
                                    b_y <= b_y - 1; 
                                end if;
                            end if;
                            
                            -- Horizontal movement, paddle collision, and scoring
                            if b_dx = '1' then  -- Moving right
                                -- Check collision with right paddle
                                if (b_x + BALL_SIZE >= FRAME_WIDTH - PADDLE_OFFSET - PADDLE_W) and
                                   (b_x + BALL_SIZE <= FRAME_WIDTH - PADDLE_OFFSET) and
                                   (b_y + BALL_SIZE >= pr_y) and (b_y <= pr_y + PADDLE_H) then
                                    b_dx <= '0';  -- Bounce left
                                -- Ball missed right paddle
                                elsif b_x >= (FRAME_WIDTH - BALL_SIZE - SAFETY_MARGIN) then
                                    if sc_l < 3 then sc_l <= sc_l + 1; end if;  -- Left player scores
                                    
                                    if lives_reg = 1 then 
                                        lives_reg <= 0; 
                                        state <= GAMEOVER; 
                                    else 
                                        lives_reg <= lives_reg - 1; 
                                        state <= SERVE; 
                                    end if;
                                else
                                    b_x <= b_x + 1;  -- Continue moving
                                end if;
                            else  -- Moving left
                                -- Check collision with left paddle
                                if (b_x <= PADDLE_OFFSET + PADDLE_W) and (b_x >= PADDLE_OFFSET) and
                                   (b_y + BALL_SIZE >= pl_y) and (b_y <= pl_y + PADDLE_H) then
                                    b_dx <= '1';  -- Bounce right
                                -- Ball missed left paddle
                                elsif b_x <= SAFETY_MARGIN then
                                    if sc_r < 3 then sc_r <= sc_r + 1; end if;  -- Right player scores
                                    
                                    if lives_reg = 1 then 
                                        lives_reg <= 0; 
                                        state <= GAMEOVER; 
                                    else 
                                        lives_reg <= lives_reg - 1; 
                                        state <= SERVE; 
                                    end if;
                                else
                                    b_x <= b_x - 1;  -- Continue moving
                                end if;
                            end if;
                        end if;
                    
                    when GAMEOVER =>
                        -- Wait for reset button
                        null;
               end case;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Output Assignments
    -------------------------------------------------------------------------
    -- Position outputs
    ball_x  <= b_x;
    ball_y  <= b_y;
    pad_l_y <= pl_y;
    pad_r_y <= pr_y;
    
    -- Score and state outputs
    score_l <= sc_l;
    score_r <= sc_r;
    lives   <= lives_reg;
    game_state_out <= state;

end Behavioral;
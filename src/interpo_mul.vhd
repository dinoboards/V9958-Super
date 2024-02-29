
-- Signed multiplier for linear interpolation filter --
LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY INTERPO_MUL IS
    GENERIC (
        MSBI    : INTEGER
    );
    PORT (
        DIFF    : IN    STD_LOGIC_VECTOR( MSBI+1 DOWNTO 0 );    --  符号付き
        WEIGHT  : IN    STD_LOGIC_VECTOR( 2      DOWNTO 0 );    --  符号無し
        OFF     : OUT   STD_LOGIC_VECTOR( MSBI+4 DOWNTO 0 )     --  符号付き
    );
END INTERPO_MUL;

ARCHITECTURE RTL OF INTERPO_MUL IS
    SIGNAL W_OFF    : STD_LOGIC_VECTOR( MSBI+5 DOWNTO 0 );
BEGIN
    W_OFF   <= DIFF * ('0' & WEIGHT);
    OFF     <= W_OFF( MSBI+4 DOWNTO 0 );
END RTL;

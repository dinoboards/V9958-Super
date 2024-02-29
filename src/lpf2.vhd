
--  LPF [1:1:1:1:1:1:1:1]/8
LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY LPF2 IS
    GENERIC (
        MSBI    : INTEGER
    );
    PORT(
        CLK21M  : IN    STD_LOGIC;
        RESET   : IN    STD_LOGIC;
        CLKENA  : IN    STD_LOGIC;
        IDATA   : IN    STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
        ODATA   : OUT   STD_LOGIC_VECTOR( MSBI DOWNTO 0 )
    );
END LPF2;

ARCHITECTURE RTL OF LPF2 IS
    SIGNAL FF_D1    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D2    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D3    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D4    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D5    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D6    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D7    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D8    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_OUT   : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );

    SIGNAL W_1      : STD_LOGIC_VECTOR( MSBI + 1 DOWNTO 0 );
    SIGNAL W_3      : STD_LOGIC_VECTOR( MSBI + 1 DOWNTO 0 );
    SIGNAL W_5      : STD_LOGIC_VECTOR( MSBI + 1 DOWNTO 0 );
    SIGNAL W_7      : STD_LOGIC_VECTOR( MSBI + 1 DOWNTO 0 );

    SIGNAL W_11     : STD_LOGIC_VECTOR( MSBI + 2 DOWNTO 0 );
    SIGNAL W_13     : STD_LOGIC_VECTOR( MSBI + 2 DOWNTO 0 );

    SIGNAL W_OUT    : STD_LOGIC_VECTOR( MSBI + 3 DOWNTO 0 );
BEGIN

    ODATA   <= FF_OUT;

    W_1     <= ('0' & FF_D1) + ('0' & FF_D8);
    W_3     <= ('0' & FF_D2) + ('0' & FF_D7);
    W_5     <= ('0' & FF_D3) + ('0' & FF_D6);
    W_7     <= ('0' & FF_D4) + ('0' & FF_D5);

    W_11    <= ('0' & W_1) + ('0' & W_5);
    W_13    <= ('0' & W_3) + ('0' & W_7);

    W_OUT   <= ('0' & W_11) + ('0' & W_13);

    -- DELAY LINE
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            FF_D1   <= ( OTHERS => '0' );
            FF_D2   <= ( OTHERS => '0' );
            FF_D3   <= ( OTHERS => '0' );
            FF_D4   <= ( OTHERS => '0' );
            FF_D5   <= ( OTHERS => '0' );
            FF_D6   <= ( OTHERS => '0' );
            FF_D7   <= ( OTHERS => '0' );
            FF_D8   <= ( OTHERS => '0' );
            FF_OUT  <= ( OTHERS => '0' );
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( CLKENA = '1' )THEN
                FF_D1   <= IDATA;
                FF_D2   <= FF_D1;
                FF_D3   <= FF_D2;
                FF_D4   <= FF_D3;
                FF_D5   <= FF_D4;
                FF_D6   <= FF_D5;
                FF_D7   <= FF_D6;
                FF_D8   <= FF_D7;
                FF_OUT  <= W_OUT( W_OUT'HIGH DOWNTO 3 );
            END IF;
        END IF;
    END PROCESS;
END RTL;

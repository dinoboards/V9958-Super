

-- Linear interpolation filter --
LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY INTERPO IS
    GENERIC (
        MSBI    : INTEGER
    );
    PORT (
        CLK21M  : IN    STD_LOGIC;
        RESET   : IN    STD_LOGIC;
        CLKENA  : IN    STD_LOGIC;
        IDATA   : IN    STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
        ODATA   : OUT   STD_LOGIC_VECTOR( MSBI DOWNTO 0 )
    );
END INTERPO;

ARCHITECTURE RTL OF INTERPO IS
    COMPONENT INTERPO_MUL
        GENERIC (
            MSBI    : INTEGER
        );
        PORT (
            DIFF    : IN    STD_LOGIC_VECTOR( MSBI+1 DOWNTO 0 );    --  符号付き
            WEIGHT  : IN    STD_LOGIC_VECTOR( 2      DOWNTO 0 );    --  符号無し
            OFF     : OUT   STD_LOGIC_VECTOR( MSBI+4 DOWNTO 0 )     --  符号付き
        );
    END COMPONENT;

    SIGNAL FF_D1        : STD_LOGIC_VECTOR( MSBI   DOWNTO 0 );
    SIGNAL FF_D2        : STD_LOGIC_VECTOR( MSBI   DOWNTO 0 );
    SIGNAL FF_WEIGHT    : STD_LOGIC_VECTOR( 2      DOWNTO 0 );

    SIGNAL W_DIFF       : STD_LOGIC_VECTOR( MSBI+1 DOWNTO 0 );
    SIGNAL W_OFF        : STD_LOGIC_VECTOR( MSBI+4 DOWNTO 0 );
    SIGNAL W_MUL5       : STD_LOGIC_VECTOR( MSBI+6 DOWNTO 0 );
    SIGNAL W_OUT        : STD_LOGIC_VECTOR( MSBI+1 DOWNTO 0 );
BEGIN

    --  遅延ライン --
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            FF_D2 <= (OTHERS => '0');
            FF_D1 <= (OTHERS => '0');
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( CLKENA = '1' )THEN
                FF_D2 <= IDATA;
                FF_D1 <= FF_D2;
            END IF;
        END IF;
    END PROCESS;

    --  補間係数 --
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            FF_WEIGHT <= (OTHERS => '0');
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( CLKENA = '1' )THEN
                FF_WEIGHT <= (OTHERS => '0');
            ELSE
                FF_WEIGHT <= FF_WEIGHT + 1;
            END IF;
        END IF;
    END PROCESS;

    --  補間 --
    --  O = ((D1 * (6-W)) + D2 * W) / 6 = (D1 * 6 - D1 * W + D2 * W) / 6 = D1 + ((D2 - D1) * W) / 6;
    W_DIFF  <= ('0' & FF_D2) - ('0' & FF_D1);   --  符号付き    --

    U_INTERPO_MUL: INTERPO_MUL
    GENERIC MAP (
        MSBI    => MSBI
    )
    PORT MAP (
        DIFF    => W_DIFF,
        WEIGHT  => FF_WEIGHT,
        OFF     => W_OFF
    );

    W_MUL5  <= (W_OFF & "00") + (W_OFF(MSBI+4) & W_OFF(MSBI+4) & W_OFF);
    W_OUT   <= ('0' & FF_D1) + W_MUL5( W_MUL5'HIGH DOWNTO 5 );

    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            ODATA <= (OTHERS => '0');
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( W_OUT( W_OUT'HIGH ) = '0' )THEN
                ODATA <= W_OUT( MSBI DOWNTO 0 );
            ELSE
                ODATA <= (OTHERS => '1');   --  飽和
            END IF;
        END IF;
    END PROCESS;
END RTL;

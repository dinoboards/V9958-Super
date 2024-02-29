--
-- lpf.vhd
--   low pass filter
--   Revision 1.00
--
-- Copyright (c) 2007 Takayuki Hara.
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--


--  LPF [1:4:6:4:1]/16
LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY LPF1 IS
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
END LPF1;

ARCHITECTURE RTL OF LPF1 IS
    SIGNAL FF_D1    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D2    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D3    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D4    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_D5    : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );
    SIGNAL FF_OUT   : STD_LOGIC_VECTOR( MSBI DOWNTO 0 );

    SIGNAL W_0      : STD_LOGIC_VECTOR( MSBI + 3 DOWNTO 0 );
    SIGNAL W_1      : STD_LOGIC_VECTOR( MSBI + 3 DOWNTO 0 );
    SIGNAL W_2      : STD_LOGIC_VECTOR( MSBI + 1 DOWNTO 0 );
    SIGNAL W_OUT    : STD_LOGIC_VECTOR( MSBI + 4 DOWNTO 0 );
BEGIN

    ODATA   <= FF_OUT;

    W_0     <= ('0' & FF_D3 & "00") + ("00" & FF_D3 & '0');     --  FF_D3 * 6
    W_1     <= (('0' & FF_D2) + ('0' & FF_D4)) & "00";          --  (FF_D2 + DD_D4) * 4
    W_2     <= ('0' & FF_D1) + ('0' & FF_D5);                   --  FF_D1 + FF_D5

    W_OUT   <= ('0' & W_0) + ('0' & W_1) + ("00" & W_2);

    -- DELAY LINE
    PROCESS( RESET, CLK21M )
    BEGIN
        IF( RESET = '1' )THEN
            FF_D1   <= ( OTHERS => '0' );
            FF_D2   <= ( OTHERS => '0' );
            FF_D3   <= ( OTHERS => '0' );
            FF_D4   <= ( OTHERS => '0' );
            FF_D5   <= ( OTHERS => '0' );
            FF_OUT  <= ( OTHERS => '0' );
        ELSIF( CLK21M'EVENT AND CLK21M = '1' )THEN
            IF( CLKENA = '1' )THEN
                FF_D1   <= IDATA;
                FF_D2   <= FF_D1;
                FF_D3   <= FF_D2;
                FF_D4   <= FF_D3;
                FF_D5   <= FF_D4;
                FF_OUT  <= W_OUT( W_OUT'HIGH DOWNTO 4 );
            END IF;
        END IF;
    END PROCESS;
END RTL;


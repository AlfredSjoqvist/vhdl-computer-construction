--------------------------------------------------------------------------------
-- PRETENDED_CPU
-- Version 1.0: See KBD_ENC.
-- Version 2.0: 2023-01-12. Petter Kallstrom. Changelog: Moved this to an own module
-- Description:
-- * This reads scancodes, and writes to the video RAM
-- * This module is instead of a CPU.

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity PRET_CPU is
	port (
		clk      : in std_logic;   -- system clock (100 MHz)
		rst      : in std_logic;   -- reset signal
		ScanCode : in std_logic_vector(7 downto 0);   -- scancode byte
		make_op  : in std_logic;                      -- one-pulsed scancode-enable
		data     : out std_logic_vector(7 downto 0);  -- tile data
		addr     : out unsigned(10 downto 0);         -- tile address
		we       : out std_logic);                    -- write enable
end PRET_CPU;

-- architecture
architecture behavioral of PRET_CPU is
	
	signal TileIndex : std_logic_vector(7 downto 0); -- tile index
	
	type curmov_type is (FORWARD, BACKWARD, NEWLINE); -- declare cursor movement types
	signal curMovement : curmov_type;                 -- cursor movement
	
	signal curposX : unsigned(5 downto 0); -- cursor X position
	signal curposY : unsigned(4 downto 0); -- cursor Y position
	
	type wr_type is (STANDBY, WRINDEX, WRCUR); -- declare state types for write cycle
	signal WRstate : wr_type;                  -- write cycle state
	
begin
	
	-- Scan Code -> Tile Index mapping
	with ScanCode select
		TileIndex <=
			x"00" when x"29", -- space
			x"01" when x"1C", -- A
			x"02" when x"32", -- B
			x"03" when x"21", -- C
			x"04" when x"23", -- D
			x"05" when x"24", -- E
			x"06" when x"2B", -- F
			x"07" when x"34", -- G
			x"08" when x"33", -- H
			x"09" when x"43", -- I
			x"0A" when x"3B", -- J
			x"0B" when x"42", -- K
			x"0C" when x"4B", -- L
			x"0D" when x"3A", -- M
			x"0E" when x"31", -- N
			x"0F" when x"44", -- O
			x"10" when x"4D", -- P
			x"11" when x"15", -- Q
			x"12" when x"2D", -- R
			x"13" when x"1B", -- S
			x"14" when x"2C", -- T
			x"15" when x"3C", -- U
			x"16" when x"2A", -- V
			x"17" when x"1D", -- W
			x"18" when x"22", -- X
			x"19" when x"35", -- Y
			x"1A" when x"1A", -- Z
			x"1B" when x"54", -- Å
			x"1C" when x"52", -- Ä
			x"1D" when x"4C", -- Ö
			x"00" when others;
	
	
	-- set cursor movement based on scan code
	with ScanCode select
		curMovement <=
			NEWLINE  when x"5A",  -- enter scancode (5A), so move cursor to next line
			BACKWARD when x"66",  -- backspace scancode (66), so move cursor backward
			FORWARD  when others; -- for all other scancodes, move cursor forward
	
	
	-- curposX
	-- update cursor X position based on current cursor position (curposX and curposY) and cursor
	-- movement (curMovement)
	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				curposX <= (others => '0');
			elsif WRstate = WRINDEX then
				if curMovement = FORWARD then
					if curposX = 19 then
						curposX <= (others => '0');
					else
						curposX <= curposX + 1;
					end if;
				elsif curMovement = BACKWARD then
					if (curposX = 0) and (curposY >= 0) then
						curposX <= to_unsigned(19, curposX'length);
					else
						curposX <= curposX - 1;
					end if;
				elsif curMovement = NEWLINE then
					curposX <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	
	
	-- curposY
	-- update cursor Y position based on current cursor position (curposX and curposY) and cursor
	-- movement (curMovement)
	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				curposY <= (others => '0');
			elsif WRstate = WRINDEX then
				if curMovement = FORWARD then
					if curposX = 19 then
						if curposY = 14 then
							curposY <= (others => '0');
						else
							curposY <= curposY + 1;
						end if;
					end if;
				elsif curMovement = BACKWARD then
					if curposX = 0 then
						if curposY = 0 then
							curposY <= to_unsigned(14, curposY'length);
						else
							curposY <= curposY - 1;
						end if;
					end if;
				elsif curMovement = NEWLINE then
					if curposY = 14 then
						curposY <= (others => '0');
					else
						curposY <= curposY + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	
	-- write state
	-- every write cycle begins with writing the character tile index at the current
	-- cursor position, then moving to the next cursor position and there write the
	-- cursor tile index
	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				WRstate <= STANDBY;
			else
				case WRstate is
					when STANDBY =>
						if make_op = '1' then
							WRstate <= WRINDEX;
						else
							WRstate <= STANDBY;
						end if;
					when WRINDEX =>
						WRstate <= WRCUR;
					when WRCUR =>
						WRstate <= STANDBY;
					when others =>
						WRstate <= STANDBY;
				end case;
			end if;
		end if;
	end process;
	
	
	-- we will be enabled ('1') for two consecutive clock cycles during WRINDEX and WRCUR states
	-- and disabled ('0') otherwise at STANDBY state
	we <= '0' when (WRstate = STANDBY) else '1';
	
	
	-- memory address is a composite of curposY and curposX
	-- the "to_unsigned(20, 6)" is needed to generate a correct size of the resulting unsigned vector
	addr <= to_unsigned(20, 6)*curposY + curposX;
	
	
	-- data output is set to be x"1F" (cursor tile index) during WRCUR state, otherwise set as scan code tile index
	data <= x"1F" when (WRstate =  WRCUR) else TileIndex;
	
	
end behavioral;


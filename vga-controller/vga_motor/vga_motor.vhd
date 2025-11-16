--------------------------------------------------------------------------------
-- VGA MOTOR
-- Version 1.1: 2016-02-16, Anders Nilsson
-- Version 1.2: 2023-01-11, Petter Kallstrom. Changelog: Corrected a pipeline mistake.
-- Version 2.0: 2023-09-29. Anders Nilsson. 12-bit VGA.


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity vga_motor is
        port (
                clk      : in  std_logic;
                VR_data  : in  std_logic_vector(7 downto 0);
                VR_addr  : out unsigned(10 downto 0);
                clear    : in  std_logic;
                vgaRed   : out std_logic_vector(3 downto 0);
                vgaGreen : out std_logic_vector(3 downto 0);
                vgaBlue  : out std_logic_vector(3 downto 0);
                Hsync    : out std_logic;
                Vsync    : out std_logic);
end vga_motor;


-- architecture
architecture Behavioral of vga_motor is
        
        signal Xpixel1, Xpixel2 : unsigned(9 downto 0);  -- Horizontal pixel counter, and its pipelined version
        signal Ypixel1, Ypixel2 : unsigned(9 downto 0);  -- Vertical pixel counter
        signal ClkDiv           : unsigned(1 downto 0);  -- Clock divisor, to generate 25 MHz signal
        signal Clk25            : std_logic;  -- One pulse width 25 MHz signal

        signal CR_addr : unsigned(10 downto 0);  -- address for CHAR_ROM
        signal CR_data : std_logic_vector(11 downto 0);  -- data from CHAR_ROM.

        signal blank1, blank2, blank : std_logic;  -- blanking signal, with delayed versions
        signal Hsync1, Hsync2        : std_logic;
        signal Vsync1, Vsync2        : std_logic;

        -- Character image rom:
        component char_rom is
                port (
                        clk  : in  std_logic;
                        addr : in  unsigned(10 downto 0);
                        data : out std_logic_vector(11 downto 0));
        end component;
        
begin

        -- Clock divisor
        -- Divide system clock (100 MHz) by 4
        process(clk)
        begin
                if rising_edge(clk) then
                        if clear = '1' then
                                ClkDiv <= (others => '0');
                        else
                                ClkDiv <= ClkDiv + 1;
                        end if;
                end if;
        end process;

        -- 25 MHz clock (one system clock pulse width)
        Clk25 <= '1' when (ClkDiv = 3) else '0';

        -- ClkDiv:  | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 |
        -- Clk25:   |___|___|___|---|___|___|___|---|___|___|___|---|
        -- Xpixel1: |<     ...     >|<     ...     >|<     ...     >|
        -- Ypixel1: ...            >|<     ...                       
        -- VR_addr: |<     ...     >|<     ...     >|<     ...     >|  f(*pixel)
        -- VR_data: ...>|<     ...     >|<     ...     >|<     ...     f(addr) @ cc
        -- CR_Addr: ...>|<     ...     >|<     ...     >|<     ...     f(data, *pixel)
        -- CR_data:     ...>|<     ...     >|<     ...     >|< ...     f(tAddr) @ cc
        -- RGB:         ...>|<     ...     >|<     ...     >|< ...     f(tPixel)
        -- blank1:  |___|___|___|___|---|---|---|---|___|___|___|___|
        -- blank2:  |___|___|___|___|___|---|---|---|---|___|___|___|
        -- *sync1:  |---|---|---|---|___|___|___|___|---|---|---|---|
        -- *sync2:  |---|---|---|---|---|___|___|___|___|---|---|---|
        -- *sync:   |---|---|---|---|---|---|___|___|___|___|---|---|


        -- Horizontal pixel counter
        -- *******************************
        -- *                             *
        -- *  VHDL for:                  *
        -- *  Xpixel1                    *
        -- *                             *
        -- *******************************

        xpixel_cntr : process(clk)
        begin
          if rising_edge(clk) then
            if clear = '1' then
              xpixel1 <= (others => '0');
            elsif clk25 = '1' then
              if to_unsigned(0, xpixel1'length) <= xpixel1 and xpixel1 < to_unsigned(640 + 16 + 96 + 48 - 1, xpixel1'length) then
                xpixel1 <= xpixel1 + to_unsigned(1, xpixel1'length);
              else
                xpixel1 <= (others => '0');
              end if;
            end if;
          end if;
        end process;

        -- Horizontal sync
        -- *******************************
        -- *                             *
        -- *  VHDL for:                  *
        -- *  Hsync1                     *
        -- *                             *
        -- *******************************

        hsync1 <= '0' when to_unsigned(640 + 16, xpixel1'length) <= xpixel1 and xpixel1 < to_unsigned(640 + 16 + 96, xpixel1'length) else '1';
      
        -- Vertical pixel counter
        -- *******************************
        -- *                             *
        -- *  VHDL for:                  *
        -- *  Ypixel1                    *
        -- *                             *
        -- *******************************

        ypixel_cntr : process(clk)
        begin
          if rising_edge(clk) then
            if clear = '1' then
              ypixel1 <= (others => '0');
            elsif clk25 = '1' and xpixel1 = to_unsigned(640 + 16 + 96 + 48 - 1, xpixel1'length) then
              if to_unsigned(0, ypixel1'length) <= ypixel1 and ypixel1 < to_unsigned(480 + 10 + 2 + 29 - 1, ypixel1'length) then
                ypixel1 <= ypixel1 + to_unsigned(1, ypixel1'length);
              else
                ypixel1 <= (others => '0');
              end if;
            end if;
          end if;
        end process;

        -- Vertical Sync
        -- *******************************
        -- *                             *
        -- *  VHDL for:                  *
        -- *  Vsync1                     *
        -- *                             *
        -- *******************************

        vsync1 <= '0' when to_unsigned(480 + 10 - 5, ypixel1'length) <= ypixel1 and ypixel1 < to_unsigned(480 + 10 + 2, ypixel1'length) else '1';

        -- Video blanking signal
        -- *******************************
        -- *                             *
        -- *  VHDL for:                  *
        -- *  Blank1                     *
        -- *                             *
        -- *******************************

        blank1 <= '0' when to_unsigned(480, ypixel1'length) > ypixel1 and xpixel1 < to_unsigned(640, xpixel1'length) else '1';

        -- Video ram address composite
        VR_addr <= to_unsigned(20, 7) * Ypixel1(8 downto 5) + Xpixel1(9 downto 5);

        -- VIDEO_RAM:
        -- data <= mem(addr), with one clock cycle delay

        process(clk)
        begin
                if rising_edge(clk) then
                        blank2  <= blank1;
                        Hsync2  <= Hsync1;
                        Vsync2  <= Vsync1;
                        Xpixel2 <= Xpixel1;
                        Ypixel2 <= Ypixel1;
                end if;
        end process;


        -- Character rom address:
        CR_addr <= unsigned(VR_data(4 downto 0)) & Ypixel2(4 downto 2) & Xpixel2(4 downto 2);

        U0b : char_rom port map (clk => clk, addr => CR_addr, data => CR_data);  -- one clock cycle delay.

        process(clk)
        begin
                if rising_edge(clk) then
                        Hsync <= Hsync2;
                        Vsync <= Vsync2;
                        blank <= blank2;
                end if;
        end process;


        -- VGA generation : 4 bit red, 4 bit green ,4 bit blue
        vgaRed(3)   <= CR_data(11) when blank = '0' else '0';
        vgaRed(2)   <= CR_data(10) when blank = '0' else '0';
        vgaRed(1)   <= CR_data(9)  when blank = '0' else '0';
        vgaRed(0)   <= CR_data(8)  when blank = '0' else '0';
        vgaGreen(3) <= CR_data(7)  when blank = '0' else '0';
        vgaGreen(2) <= CR_data(6)  when blank = '0' else '0';
        vgaGreen(1) <= CR_data(5)  when blank = '0' else '0';
        vgaGreen(0) <= CR_data(4)  when blank = '0' else '0';
        vgaBlue(3)  <= CR_data(3)  when blank = '0' else '0';
        vgaBlue(2)  <= CR_data(2)  when blank = '0' else '0';
        vgaBlue(1)  <= CR_data(1)  when blank = '0' else '0';
        vgaBlue(0)  <= CR_data(0)  when blank = '0' else '0';
        
end Behavioral;


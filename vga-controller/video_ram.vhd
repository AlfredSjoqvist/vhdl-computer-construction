--------------------------------------------------------------------------------
-- PICT MEM
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1
-- Version 2.0: 2023-09-29. Anders Nilsson. Separate processes for ports in VideoRAM (block RAM).
-- * Separate processes is necessary when buiding dual port block RAMs (Vivado design user guide)
-- * https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Simple-Dual-Port-Block-RAM-with-Single-Clock-VHDL
-- * The design guide also states the use of shared variables when accessing the same
-- * "signal" from several processes, such as the case with dual port block RAMs.
-- * Shared variables should further be protected:
-- * https://fpgatutorial.com/vhdl-shared-variable-protected-type/#protected-type-example
-- * https://www.linkedin.com/pulse/vhdl-shared-variables-protected-types-memory-modeling-jim-lewis

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity VIDEO_RAM is
	port (
		clk       : in std_logic;
		-- port 1
		we1       : in std_logic;
		data_in1  : in std_logic_vector(7 downto 0);
		data_out1 : out std_logic_vector(7 downto 0);
		addr1     : in unsigned(10 downto 0);
		-- port 2
		we2       : in std_logic;
		data_in2  : in std_logic_vector(7 downto 0);
		data_out2 : out std_logic_vector(7 downto 0);
		addr2     : in unsigned(10 downto 0));
end VIDEO_RAM;


-- architecture
architecture Behavioral of VIDEO_RAM is

	-- video RAM type
	type ram_t is array (0 to 2047) of std_logic_vector(7 downto 0);
	-- initiate video RAM to one cursor ("1F") followed by spaces ("00")
	--signal VideoRAM : ram_t := (0 => x"1F", others => (others => '0'));
        shared variable VideoRAM : ram_t := (0 => x"1F", others => (others => '0'));

begin

  process(clk)
  begin
    if rising_edge(clk) then
      data_out1 <= VideoRAM(to_integer(addr1));
      if (we1 = '1') then
        VideoRAM(to_integer(addr1)) := data_in1;
      end if;
    end if;
  end process;
	
  process(clk)
  begin
    if rising_edge(clk) then
      data_out2 <= VideoRAM(to_integer(addr2));
      if (we2 = '1') then
        VideoRAM(to_integer(addr2)) := data_in2;
      end if;
    end if;
  end process;

end Behavioral;

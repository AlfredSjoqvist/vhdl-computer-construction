--------------------------------------------------------------------------------
-- VGA lab
-- Anders Nilsson
-- 16-dec-2015
-- Version 1.0


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity vga_lab is
	port (
		clk      : in std_logic;                         -- system clock
		btnC     : in std_logic;                         -- center button
		Hsync    : out std_logic;                        -- horizontal sync
		Vsync    : out std_logic;                        -- vertical sync
		vgaRed   : out std_logic_vector(3 downto 0);     -- VGA red
		vgaGreen : out std_logic_vector(3 downto 0);     -- VGA green
		vgaBlue  : out std_logic_vector(3 downto 0));    -- VGA blue
end vga_lab;


-- architecture
architecture Behavioral of VGA_lab is

	-- picture memory component
	component VIDEO_RAM
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
	end component;

	-- VGA motor component
	component VGA_MOTOR
		port (
			clk      : in std_logic;
			VR_data  : in std_logic_vector(7 downto 0);
			VR_addr  : out unsigned(10 downto 0);
			clear    : in std_logic;
			vgaRed   : out std_logic_vector(3 downto 0);
			vgaGreen : out std_logic_vector(3 downto 0);
			vgaBlue  : out std_logic_vector(3 downto 0);
			Hsync    : out std_logic;
			Vsync    : out std_logic);
	end component;

	-- intermediate signals between VIDEO_RAM and VGA_MOTOR
	signal data_out2_s : std_logic_vector(7 downto 0); -- data
	signal addr2_s : unsigned(10 downto 0);            -- address

        -- synchronous clear
        signal clear : std_logic;
begin

  clear <= btnC;
  
	-- picture memory component connection
	U1 : VIDEO_RAM port map(clk=>clk, we1=>'0', data_in1=>"00000000", addr1=>"00000000000", we2=>'0', data_in2=>"00000000", data_out2=>data_out2_s, addr2=>addr2_s);

	-- VGA motor component connection
	U2 : VGA_MOTOR port map(clk=>clk, clear=>clear, VR_data=>data_out2_s, VR_addr=>addr2_s, vgaRed=>vgaRed, vgaGreen=>vgaGreen, vgaBlue=>vgaBlue, Hsync=>Hsync, Vsync=>Vsync);

end Behavioral;


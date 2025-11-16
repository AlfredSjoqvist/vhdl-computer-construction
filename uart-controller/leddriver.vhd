library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity leddriver is
    Port ( clk : in  std_logic;
           seg : out std_logic_vector(6 downto 0);
           dp : out std_logic;
           an : out std_logic_vector(3 downto 0);
           hex4 : in std_logic_vector(15 downto 0));
end leddriver;

architecture behavioral of leddriver is

  signal counter_r : unsigned(17 downto 0) := "000000000000000000";
  signal v : std_logic_vector(3 downto 0);

begin
  
  dp <= '1';    -- decimal point not used, always off
     
   with counter_r(17 downto 16) select
     v <= hex4(15 downto 12) when "00",
          hex4(11 downto 8) when "01",	
          hex4(7 downto 4) when "10",
          hex4(3 downto 0) when others;

   process(clk) begin
     if rising_edge(clk) then 
       counter_r <= counter_r + 1;
       case v is
         when "0000" => seg <= "1000000";   -- 0
         when "0001" => seg <= "1111001";   -- 1
         when "0010" => seg <= "0100100";   -- 2
         when "0011" => seg <= "0110000";   -- 3
         when "0100" => seg <= "0011001";   -- 4
         when "0101" => seg <= "0010010";   -- 5
         when "0110" => seg <= "0000010";   -- 6
         when "0111" => seg <= "1111000";   -- 7
         when "1000" => seg <= "0000000";   -- 8
         when "1001" => seg <= "0010000";   -- 9
         when "1010" => seg <= "0001000";   -- A
         when "1011" => seg <= "0000011";   -- B
         when "1100" => seg <= "1000110";   -- C
         when "1101" => seg <= "0100001";   -- D
         when "1110" => seg <= "0000110";   -- E
         when others => seg <= "0001110";   -- F
       end case;
      
       case counter_r(17 downto 16) is
         when "00" => an <= "0111";
         when "01" => an <= "1011";
         when "10" => an <= "1101";
         when others => an <= "1110";
       end case;
     end if;
   end process;
	
end behavioral;


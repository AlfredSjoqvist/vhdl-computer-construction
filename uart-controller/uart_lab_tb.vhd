-- testbench template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_lab_tb is
end uart_lab_tb;

architecture behavior of uart_lab_tb is

    -- component declaration
    component uart_lab
        port (clk : in std_logic;                     -- system clock
            btnc : in std_logic;                      -- reset button
            rsrx : in std_logic;                      -- uart rs2323 rx
            seg : out std_logic_vector(6 downto 0);   -- 7-seg, segments
            dp : out std_logic;                       -- 7-seg, decimal point
            an : out std_logic_vector (3 downto 0));  -- 7-seg, anode
    end component;

    signal clk : std_logic := '0';
    signal clear : std_logic := '0';
    signal rsrx : std_logic := '1';
    signal seg : std_logic_vector(6 downto 0);
    signal an : std_logic_vector(3 downto 0);
    signal tb_running : boolean := true;
    -- alla bitar för 1234
    signal rsrx_data : unsigned(0 to 39) := "0100011001001001100101100110010001011001";
begin

    -- component instantiation
    uut : uart_lab port map(
        clk => clk,
        btnc => clear,
        rsrx => rsrx,
        seg => seg,
        an => an);


    clk_gen : process
    begin
        while tb_running loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;



    stimuli_generator : process
        variable i : integer;
    begin
        -- aktivera reset ett litet tag.
        clear <= '1';
        wait for 500 ns;

        wait until rising_edge(clk);    -- se till att reset släpps synkront
        -- med klockan
        clear <= '0';
        report "reset released" severity note;
        wait for 1 us;

        for i in 0 to 39 loop
            rsrx <= rsrx_data(i);
            wait for 8.68 us;
        end loop;  -- i

        for i in 0 to 50000000 loop     -- vänta ett antal klockcykler
            wait until rising_edge(clk);
        end loop;  -- i

        tb_running <= false;  -- stanna klockan (vilket medför att inga
        -- nya event genereras vilket stannar
        -- simuleringen).
        wait;
    end process;
      
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_lab is
    port (clk : in std_logic;                     -- system clock
        btnc : in std_logic;                      -- reset button
        rsrx : in std_logic;                      -- uart rs232 rx
        rstx : out std_logic;                     -- uart rs232 tx
        seg : out std_logic_vector(6 downto 0);   -- 7-seg, segments
        dp : out std_logic;                       -- 7-seg, decimal point
        an : out std_logic_vector (3 downto 0));  -- 7-seg, anode
end uart_lab;

architecture behavioral of uart_lab is
    
    component leddriver
        port (clk : in std_logic;                      -- system clock
            seg : out std_logic_vector(6 downto 0);    -- 7-seg, segments
            dp : out std_logic;                        -- 7-seg, decimal point
            an : out std_logic_vector(3 downto 0);     -- 7-seg, anode
            hex4 : in std_logic_vector(15 downto 0));  -- four hex-digits
    end component;

    signal sreg : unsigned(9 downto 0) := b"0_00000000_0";  -- 10 bit shift register
    signal hex4 : unsigned(15 downto 0) := x"0000";
    signal rx1, rx2 : std_logic;        -- synchronizing flip-flops
    signal lp : std_logic;              -- load pulse
    signal pos : unsigned(1 downto 0);  -- hex-digit position

    type transmission_state is (reading, idle);
    signal state : transmission_state;  -- state of transmission
    signal clk_counter : integer range 0 to 867;  -- transmission length counter
    signal bit_counter : integer range 0 to 9;  -- sub counter to the transmission length counter
begin


    -- *****************************
    -- *  synkroniseringsvippor    *
    -- *****************************
    syncregs : process(clk)
    begin
        if rising_edge(clk) then
            if btnc = '1' then
                rx1 <= '0';
                rx2 <= '0';
            else
                rx1 <= rsrx;
                rx2 <= rx1;
            end if;
        end if;
    end process syncregs;

    -- *****************************
    -- *       styrenhet           *
    -- *****************************
    control_unit : process(clk)
    begin
        if rising_edge(clk) then
            if btnc = '1' then
                state <= idle;
                clk_counter <= 0;
            elsif state = idle then
                lp <= '0';
                if rx1 = '0' and rx2 = '1' then
                    state <= reading;
                    clk_counter <= 434;
                    bit_counter <= 0;
                end if;
            else
                if clk_counter = 867 then
                    clk_counter <= 0;

                    if bit_counter = 9 then
                        state <= idle;
                        lp <= '1';
                    else
                        bit_counter <= bit_counter + 1;
                    end if;
                else
                    clk_counter <= clk_counter + 1;
                end if;
            end if;
        end if;
    end process control_unit;


    -- *****************************
    -- * 10 bit skiftregister      *
    -- *****************************
    read_buffer : process(clk)
    begin
        if rising_edge(clk) then
            if btnc = '1' then
                sreg <= (others => '0');
            elsif clk_counter = 867 then
                sreg <= shift_right(sreg, 1);
                sreg(9) <= rx2;
            end if;
        end if;
    end process read_buffer;


    -- *****************************
    -- * 2  bit register           *
    -- *****************************
    pos_cntr : process(clk)
    begin
        if rising_edge(clk) then
            if btnc = '1' then
                pos <= (others => '0');
            elsif lp = '1' then
                pos <= pos+1;
            end if;
        end if;
    end process pos_cntr;


    -- *****************************
    -- * 16 bit register           *
    -- *****************************
    vram : process(clk)
    begin
        if rising_edge(clk) then
            if btnc = '1' then
                hex4 <= (others => '0');
            elsif lp = '1' then
                case pos is
                    when to_unsigned(0, pos'length) =>
                        hex4(15 downto 12) <= sreg(4 downto 1);
                    when to_unsigned(1, pos'length) =>
                        hex4(11 downto 8) <= sreg(4 downto 1);
                    when to_unsigned(2, pos'length) =>
                        hex4(7 downto 4) <= sreg(4 downto 1);
                    when others =>
                        hex4(3 downto 0) <= sreg(4 downto 1);
                end case;
            end if;
        end if;
    end process vram;


    -- *****************************
    -- * multiplexad display       *
    -- *****************************
    led : leddriver port map (clk => clk, seg => seg, dp => dp, an => an, hex4 => std_logic_vector(hex4));
end behavioral;


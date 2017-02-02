library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_div is
    Port (
        clock_1_8432MHz : in  STD_LOGIC; --1.8432 MHz
        reset  : in  STD_LOGIC;
        clock_115_2kHz: out STD_LOGIC -- 115.2 kHz
    );
end clk_div;

architecture Behavioral of clk_div is
    signal temporal: STD_LOGIC;
    signal counter : integer range 0 to 16 := 0;
begin
    frequency_divider: process (reset, clock_1_8432MHz) begin
        if (reset = '1') then
            temporal <= '0';
            counter <= 0;
			else
				if rising_edge(clock_1_8432MHz) then
					if (counter = 7) then
						 temporal <= NOT(temporal);
						 counter <= 0;
					else
						 counter <= counter + 1;
					end if;
					clock_115_2kHz <= temporal;
				else
					--nothing happens
				end if;
			end if;
    end process;
end Behavioral;
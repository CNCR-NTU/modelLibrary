LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY transmit232 IS
PORT(	clock_115_2KHz	: IN STD_LOGIC;
		reset				: IN STD_LOGIC;
		data				: IN STD_LOGIC_VECTOR (7 downto 0);
		datar232			: IN STD_LOGIC;
		TX232				: OUT STD_LOGIC;
		busy232			: out std_logic
		);		
END transmit232;

ARCHITECTURE Behavior OF transmit232 IS
	signal count	: std_logic_vector(15 downto 0) := (others =>'0');
	signal tx_aux 	: std_logic :='1';
	signal buffer1	: STD_LOGIC_VECTOR (7 downto 0):= "00000000";
	

BEGIN
	
process
	begin
			wait until clock_115_2KHz'event and clock_115_2KHz = '1';
				if reset = '1' then
					count<=(others =>'0');
					tx_aux<='1';
					buffer1<= "00000000";
					busy232<='0';
				else
				--////////////// SEND VALUES /////////////////////
				-- 1 Start bit | 8 bits | 1 Stop bit
				-- f0=115.200 Khz
					if datar232 = '1' and count = 0 then 
						buffer1<=data;
						busy232<='1';
						tx_aux<= '0';  --Start bit
						count <= count +1;
						
					elsif count = 1 then 
						tx_aux<= buffer1(0);
						count <= count +1;
						
					elsif count = 2 then 
						tx_aux<= buffer1(1);
						count <= count +1;
						
					elsif count = 3 then 
						tx_aux<= buffer1(2);
						count <= count +1;

					elsif count = 4 then 
						tx_aux<= buffer1(3);
						count <= count +1;
						
					elsif count = 5 then 
						tx_aux<= buffer1(4);
						count <= count +1;

					elsif count = 6 then 
						tx_aux<= buffer1(5);
						count <= count +1;

					elsif count = 7 then 
						tx_aux<= buffer1(6);
						count <= count +1;

					elsif count = 8 then 
						tx_aux<= buffer1(7);
						count <= count +1;
						
					-- 1st stop bit
					elsif count >=9 and  count < 300 then
						count <= count +1;
						tx_aux<='1';
						
					elsif count = 300 then
						count<=(others =>'0');
						buffer1<= "00000000";
						busy232<='0';
						
					else
						tx_aux<='1';
					end if;
				end if;
				TX232<=tx_aux;
	END PROCESS;	
END Behavior;
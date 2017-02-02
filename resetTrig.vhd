LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY resetTrig IS
PORT(	clk	: IN STD_LOGIC;
		reset					: IN STD_LOGIC;
		resetTri				: IN STD_LOGIC;
		res					: OUT STD_LOGIC
		);		
END resetTrig;

ARCHITECTURE Behavior OF resetTrig IS
	signal count	: natural 								:= 0;

BEGIN
	
process
	begin
			wait until clk'event and clk = '1';
			if reset = '1' then
				count<=1;
			else
				if resetTri = '1' then
					count<=1;
				elsif count>0 and count < 440 then 
					count <= count +1;
					res<='1';
				elsif count=440 then
					res<='0';
					count<=0;	
				else
				end if;
			end if;
	END PROCESS;	
END Behavior;
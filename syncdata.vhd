LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

ENTITY syncdata IS

generic 
	(
		DATA_WIDTH : natural := 56;
		ADDR_WIDTH : natural := 32
	);

PORT(	clock_115_2_KHz	: IN	STD_LOGIC;
		reset					: IN	STD_LOGIC;
		q						: IN std_logic_vector((DATA_WIDTH -1) downto 0);
		busy232				: IN  STD_LOGIC;
		queue					: IN 	std_logic_vector((ADDR_WIDTH-1) downto 0);
		data232				: OUT	STD_LOGIC_VECTOR (7 downto 0);
		data232_ready		: OUT std_logic;
		raddr					: out std_logic_vector((ADDR_WIDTH-1) downto 0)
		); 
		
		
END syncdata;

ARCHITECTURE Behavior OF syncdata IS

	signal	count 				: natural 												:= 0;
	signal 	indexp				: std_logic_vector((ADDR_WIDTH-1) downto 0)	:= (others =>'0');
	signal	index2p				: std_logic_vector((ADDR_WIDTH-1) downto 0)	:= (others =>'0');
	signal 	busy					: STD_LOGIC												:= '0';
	

	BEGIN

	process(clock_115_2_KHz, reset )
	begin
	if(rising_edge(clock_115_2_KHz)) then 
		if(reset ='1') then
			index2p<=(others =>'0');
			raddr<=(others =>'0');
			indexp<=(others =>'0');
			count<=0;
			data232<=(others=>'0');
			data232_ready<='0';
			busy<='0';
		else
			if index2p>indexp and busy232='0' and count=0 then
				data232<=q(55 downto 48);
				data232_ready<='1';
				count<=count+1;
				busy<='1';
			elsif count=1 then
				count<=count+1;
				data232_ready<='0';
			elsif busy232='0' and count=2 then
				data232<=q(47 downto 40);
				data232_ready<='1';
				count<=count+1;
			elsif count=3 then
				count<=count+1;
				data232_ready<='0';
			elsif busy232='0' and count=4 then
				data232<=q(39 downto 32);
				data232_ready<='1';
				count<=count+1;
			elsif count=5 then
				count<=count+1;
				data232_ready<='0';
			elsif busy232='0' and count=6 then
				data232<=q(31 downto 24);
				data232_ready<='1';
				count<=count+1;
			elsif count=7 then
				count<=count+1;
				data232_ready<='0';
			elsif busy232='0' and count=8 then
				data232<=q(23 downto 16);
				data232_ready<='1';
				count<=count+1;
			elsif count=9 then
				count<=count+1;
				data232_ready<='0';
			elsif busy232='0' and count=10 then
				data232<=q(15 downto 8);
				data232_ready<='1';
				count<=count+1;
			elsif count=11 then
				count<=count+1;
				data232_ready<='0';
			elsif busy232='0' and count=12 then
				data232<=q(7 downto 0);
				data232_ready<='1';
				count<=count+1;
			elsif count=13 then
				data232_ready<='0';
				indexp<=indexp+1;
				busy<='0';
				count<=0;
			else
			end if;
			
			if (queue>0 and queue-1>index2p) and index2p=indexp and busy='0' then
				raddr<=index2p+1;
				index2p<=index2p+1;
			else
			end if;
			
		end if;
	else
	end if;
	end process;
	
END Behavior;			

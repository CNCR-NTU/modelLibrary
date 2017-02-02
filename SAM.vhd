-- Libraries used --

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.fixed_float_types.all;
--!ieee_proposed for fixed point
use ieee.fixed_pkg.all;
--!ieee_proposed for floating point
use ieee.float_pkg.all;
entity SAM is

generic 
	(
		DATA_WIDTH : natural := 56;
		ADDR_WIDTH : natural := 32
	);

port (clk		: IN std_logic;
		reset		: IN std_logic;
		data_ready: IN std_logic;
		result	: IN	STD_LOGIC_VECTOR (7 downto 0);
		waddr		: OUT std_logic_vector((ADDR_WIDTH-1) downto 0);
		data		: OUT std_logic_vector((DATA_WIDTH-1) downto 0);
		we			: OUT std_logic;
		queue		: out std_logic_vector((ADDR_WIDTH-1) downto 0);
		rst		: OUT std_logic;
		debug		: OUT std_logic_vector (7 downto 0)
		);
end SAM;

-- architecture body --
architecture SAM_arch of SAM is

-- declaration : constant and signals --
--testbench
--constant	time_step: 		std_logic_vector (15 downto 0)	:=x"0001";		-- time step 1s --
--constant	abs_ref: 		std_logic_vector (15 downto 0)	:=x"0005";		-- absolute refractory period = 5 ms --
--constant cap: 				std_logic_vector (15 downto 0)	:=x"0001";		-- capacitance = 1nF --
--constant	resistor: 		std_logic_vector (15 downto 0)	:=x"0028";		-- Leaky resistance = 40 Mohm --
--constant decayp:			std_logic_vector (15 downto 0)	:=x"0002";		-- reset voltage = 2 mV --
--constant v_th:				std_logic_vector (15 downto 0)	:=x"000A";		-- threshold voltage = 10 mV --
--constant weight1:			std_logic_vector (15 downto 0)	:=x"0001";		-- weight = 2 --
--constant weight2:			std_logic_vector (15 downto 0)	:=x"0001";		-- weight = 2 --
--constant cycles:			std_logic_vector (15 downto 0)	:=x"012C";		-- 300 cycles

signal time_step: 		std_logic_vector (15 downto 0);
signal cycles:				std_logic_vector (15 downto 0);
signal abs_ref: 			std_logic_vector (15 downto 0);
signal cap: 				std_logic_vector (15 downto 0);
signal resistor: 			std_logic_vector (15 downto 0);
signal decayp:				std_logic_vector (15 downto 0);
signal v_th:				std_logic_vector (15 downto 0);
signal weight1:			std_logic_vector (15 downto 0);
signal weight2:			std_logic_vector (15 downto 0);

signal 	V:					float32;
signal 	Vaux1:			float32;
signal 	Vaux2:			float32;
signal 	Vaux3:			float32;
signal 	Vaux4:			float32;
signal 	ref:				natural									:=0;
signal	spike:			std_logic 								:='0';
signal 	count:			natural									:=0;
signal 	timestamp:		natural									:=0;
signal 	syn1:				std_logic_vector (15 downto 0)	:=(others=>'0');
signal 	syn2:				std_logic_vector (15 downto 0)	:=(others=>'0');
signal 	csyn1:			natural									:=0;
signal 	csyn2:			natural									:=0;
signal 	qAux:				std_logic_vector((ADDR_WIDTH-1) downto 0):=(others=>'0');
signal 	ct:				natural									:=0;
signal	rst_flag: 		std_logic								:='0';
signal	flag:				std_logic 								:='0';

begin
		--- process ---
	process 
	begin
		wait until clk'EVENT and clk = '1';
		if reset='1' then
			count<=0;
			we<='0';
			waddr<=(others=>'0');
			queue<=(others=>'0');
			debug<=(others=>'0');
			V<=to_float(0.0,V);
			Vaux1<=to_float(0.0,Vaux1);
			Vaux2<=to_float(0.0,Vaux2);
			Vaux3<=to_float(0.0,Vaux3);
			Vaux4<=to_float(0.0,Vaux4);
			spike<='0';
			timestamp<=0;
			ref<=to_integer(unsigned(abs_ref));
			syn1<=weight1;
			syn2<=weight2;
			csyn1<=0;
			csyn2<=0;
			data<= (others =>'0');
			qAux<=(others=>'0');
			flag<='0';
			ct<=0;
			rst_flag<='0';
			time_step<=(others =>'0');
			cycles<=(others =>'0');
			abs_ref<=(others =>'0');
			cap<=(others =>'0');
			resistor<=(others =>'0');
			decayp<=(others =>'0');
			v_th<=(others =>'0');
			weight1<=(others =>'0');
			weight2<=(others =>'0');
		else
			if data_ready='1' and result=x"FF" and ct=0 then
				ct<=ct+1;
			elsif data_ready='1' and ct=1 then
				time_step(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=2 then
				time_step(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=3 then
				cycles(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=4 then
				cycles(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=5 then
				abs_ref(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=6 then
				abs_ref(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=7 then
				cap(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=8 then
				cap(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=9 then
				resistor(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=10 then
				resistor(7 downto 0)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=11 then
				decayp(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=12 then
				decayp(7 downto 0)<=result;
				ct<=ct+1;		
			elsif data_ready='1' and ct=13 then
				v_th(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=14 then
				v_th(7 downto 0)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=15 then
				weight1(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=16 then
				weight1(7 downto 0)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=17 then
				weight2(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=18 then
				weight2(7 downto 0)<=result;
				ct<=ct+1;		
			elsif data_ready='1' and result=x"FF" and ct=19 then
				ct<=ct+1;	
			elsif ct>19 and ct<3000 then
				ct<=ct+1;
			elsif ct=3000 then
				flag<='1';
				ct<=0;
			else
				-- nothing happens
			end if;
			
			if data_ready='1' and result=x"EE" then
				rst_flag<='1';
			elsif rst_flag='1' then
				rst_flag<='0';
			else
				-- nothing happens.
			end if;
			
			if flag='1' and timestamp < cycles then
				if count=0 then
						if csyn1 < 6 then
							csyn1<=csyn1+1;
							syn1<=(others=>'0');
						else
							csyn1<=0;
							syn1<=weight1;
						end if;
						
						if csyn2 < 13 then
							csyn2<=csyn2+1;
							syn2<=(others=>'0');
						else
							csyn2<=0;
							syn2<=weight2;
						end if;
						if V <to_float(0.0,V) then
							V <= to_float(unsigned(decayp),V);
						else
							-- Nothing happens
						end if;
					count<= count+1;
					
				elsif count=1 then
					spike<='0';
					if (ref > 0) then
						ref <= ref-1;
						count<=5;
					elsif V >= to_float(unsigned(v_th),V) then
						ref <= to_integer(unsigned(abs_ref));
						V <= V-to_float(unsigned(decayp),V);
						count<=5;
					else
						Vaux1<=to_float(unsigned(resistor)*unsigned(cap),Vaux1); --tau
						Vaux2<=to_float(unsigned(syn1+syn2),Vaux2); -- I
						Vaux3<=to_float(unsigned(resistor)*unsigned(time_step),Vaux3); --r*dt
						Vaux4<=to_float(unsigned(time_step),Vaux4); -- dt
						count<=count+1;
					end if;
				elsif count=2 then
					Vaux1<=V*Vaux4/Vaux1; --V*dt/tau
					Vaux2<=Vaux2*Vaux3/Vaux1; -- I*r*dt/tau
					count<=count+1;
					
				elsif count=3 then
					V <= V + Vaux2 - Vaux1; -- V + I*r*dt/tau - V*dt/tau
					count<=count+1;
				
				elsif count=4 then
					if V >= to_float(unsigned(v_th),V) then
						V <= to_float(unsigned(v_th),V);
						spike<='1';
					elsif V<= to_float(0.0,V) then
						V <= to_float(0.0,V);
					else
						-- do nothing
					end if;
					count<=count+1;
					
				elsif count=5 then
					we<='1';
					queue<=qAux+1;
					waddr<=qAux;
					qAux<=qAux+1;
					data(55 downto 40)<=std_logic_vector(to_unsigned(timestamp,16));
					data(39 downto 8)<=to_slv(V);
					data(0)<=spike;
					data(7 downto 1)<=(others =>'0');
					count<=count+1;
				
				elsif count=6 then
					we<='0';
					count<=0;
					timestamp<=timestamp+1;
					debug<=std_logic_vector(to_unsigned(timestamp,8));
				else
				end if;
			else
			end if;
			rst<=rst_flag;
		end if;	
	end process;
end SAM_arch;
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
entity IZK is

generic 
	(
		DATA_WIDTH : natural := 56;
		ADDR_WIDTH : natural := 16
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
end IZK;

-- architecture body --
architecture IZK_arch of IZK is

-- declaration : constant and signals --


--constant	time_step: 		std_logic_vector (15 downto 0)	:=x"0001";		-- time step 1ms --
--constant cycles:			std_logic_vector (15 downto 0)	:=x"012C";		-- 300 cycles
--constant v_th:				std_logic_vector (15 downto 0)	:=x"001E";		-- threshold voltage = 30 mV --
signal 	cycles:			std_logic_vector (15 downto 0);	
signal 	v_th:				std_logic_vector (15 downto 0);
signal	time_step: 		float32;		
signal	a:					float32;
signal 	b:					float32;
signal	c:					float32;
signal 	d:					float32;
signal	av:				float32;
signal	mr:				float32;	
signal	w1:				float32;	
signal	w2:				float32;	
signal 	aux1:				float32;
signal 	aux2:				float32;
signal 	aux3:				float32;
signal 	aux4:				float32;
signal 	aux5:				float32;
signal 	aux6:				float32;
signal 	aux7:				float32;
signal 	aux8:				float32;
signal 	aux9:				float32;
signal 	auxRes:			std_logic_vector(31 downto 0):=(others =>'0');
signal	spike:			std_logic 								:='0';
signal 	count:			natural									:=0;
signal 	timestamp:		natural									:=0;
signal 	syn1:				float32;
signal 	syn2:				float32;
signal 	csyn1:			natural									:=0;
signal 	csyn2:			natural									:=0;
signal 	qAux:				std_logic_vector((ADDR_WIDTH-1) downto 0):=(others =>'0');
signal 	ct:				natural									:=0;
signal	rst_flag: 		std_logic								:='0';
signal	flag:				std_logic 								:='0';

begin
		--- process ---
	process 
	begin
		wait until clk'EVENT and clk = '1';
		if reset='1' then
		   -- (C) tonic bursting
			--  a=0.02, b=0.25, c=-50, d=2, v0=-70 w1=2, w2=2
			--testbench
--			a<=to_float(0.02,a);
--			b<=to_float(0.25,b);
--			c<=to_float(-50.0,c);
--			d<=to_float(2.0,d);
--			w1<=to_float(0.5,w1);
--			w2<=to_float(0.5,w2);
--			av<=to_float(-70.0,av); 
--			mr<=to_float(-14.0,mr);
--			time_step<=to_float(0.5,time_step); 
			a<=to_float(0.0,a);
			b<=to_float(0.0,b);
			c<=to_float(0.0,c);
			d<=to_float(0.0,d);
			w1<=to_float(0.0,w1);
			w2<=to_float(0.0,w2);
			av<=to_float(0.0,av); 
			mr<=to_float(0.0,mr);
			time_step<=to_float(0.0,time_step);
			aux1<=to_float(0.0,aux1);
			aux2<=to_float(0.0,aux2);
			aux3<=to_float(0.0,aux3);
			aux4<=to_float(0.0,aux4);
			aux5<=to_float(0.0,aux5);
			aux6<=to_float(0.0,aux6);
			aux7<=to_float(0.0,aux7);
			aux8<=to_float(0.0,aux8);
			aux9<=to_float(0.0,aux9);
			syn1<=to_float(0.0,syn1);
			syn2<=to_float(0.0,syn2);
			count<=0;
			we<='0';
			waddr<=(others =>'0');
			queue<=(others =>'0');
			debug<=(others=>'0');
			spike<='0';
			timestamp<=0;
			csyn1<=0;
			csyn2<=0;
			data<= (others =>'0');
			qAux<=(others =>'0');
			flag<='0';
			ct<=0;
			rst_flag<='0';
			cycles<=(others =>'0');
			v_th<=(others =>'0');
			auxRes<=(others =>'0');
		else
			
			if data_ready='1' and result=x"FF" and ct=0 then
				ct<=ct+1;
			elsif data_ready='1' and ct=1 then
				cycles(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=2 then
				cycles(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=3 then
				v_th(15 downto 8)<=result;
				ct<=ct+1;		
			elsif data_ready='1' and ct=4 then
				v_th(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=5 then
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=6 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=7 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=8 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=9 then
				time_step<=to_float(auxRes,time_step);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=10 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=11 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=12 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=13 then
				a<=to_float(auxRes,a);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=14 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=15 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=16 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=17 then
				b<=to_float(auxRes,b);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=18 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=19 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=20 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=21 then
				c<=to_float(auxRes,c);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=22 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=23 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=24 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=25 then
				d<=to_float(auxRes,d);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=26 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=27 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=28 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=29 then
				w1<=to_float(auxRes,w1);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=30 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=31 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=32 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=33 then
				w2<=to_float(auxRes,w2);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=34 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=35 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=36 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=37 then
				av<=to_float(auxRes,av);
				auxRes(31 downto 24)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=38 then
				auxRes(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=39 then
				auxRes(15 downto 8)<=result;
				ct<=ct+1;	
			elsif data_ready='1' and ct=40 then
				auxRes(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and result=x"FF" and ct=41 then
				mr<=to_float(auxRes,mr);
				ct<=ct+1;	
			elsif ct>41 and ct<3000 then
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
					if spike='1' then
						spike<='0';
					else
					end if;
					--if csyn1 < 3 then
					--	csyn1<=csyn1+1;
					--	syn1<=to_float(0.0,syn1);
					--else
					--	csyn1<=0;
					syn1<=w1;
					--end if;
						
					--if csyn2 < 7 then
					--	csyn2<=csyn2+1;
					--	syn2<=to_float(0.0,syn2);
					--else
					--	csyn2<=0;
					syn2<=w2;
					--end if;
					count<= count+1;
					
				elsif count=1 then
					aux1<=syn2+syn1; --I
					aux2<=time_step*to_float(0.04,aux2); --0.04*dt
					aux3<=av*to_float(5.0,aux3); --5.0*v
					aux4<=a*b; --a*b
					aux5<=a*mr; --a*u
					aux6<=to_float(unsigned(v_th),aux6);
					aux7<=time_step*to_float(140.0,aux7); --140.0*dt
					aux8<=av*av; -- v^2
					aux9<=mr*time_step; --u*dt
					count<=count+1;
				
				elsif count=2 then
					aux1<=time_step*aux1; --I*dt
					aux2<=aux2*aux8; --0.04*v^2*dt
					aux3<=time_step*aux3; --5.0*v*dt
					aux4<=av*aux4;--a*b*v
					count<=count+1;
					
				elsif count=3 then
					count<=count+1;
					av<=av+aux2+aux3+aux7-aux9+aux1; --v + 0.04*v^2*dt+5.0*v*dt+140.0*dt - u*dt+I*dt
				
				elsif count=4 then
					count<=count+1;
					av<=av+aux2+aux3+aux7-aux9+aux1; --v + 0.04*v^2*dt+5.0*v*dt+140.0*dt - u*dt+I*dt
					mr<=mr+aux4-aux5; --mr + a*b*v-a*u
				
				elsif count=5 then
					if av >= aux6 then
						data(39 downto 8)<=to_slv(aux6);
						av<=c;
						mr<=mr+d;
						spike<='1';
					else
						data(39 downto 8)<=to_slv(aV);
					end if;
					count<=count+1;
				
				elsif count=6 then
					we<='1';
					queue<=qAux+1;
					waddr<=qAux;
					qAux<=qAux+1;
					data(55 downto 40)<=std_logic_vector(to_unsigned(timestamp,16));
					data(0)<=spike;
					data(7 downto 1)<=(others =>'0');
					count<=count+1;
				
				elsif count=7 then
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
end IZK_arch;
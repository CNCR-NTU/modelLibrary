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

entity AVA is

generic 
	(
		DATA_WIDTH : natural := 56;
		ADDR_WIDTH : natural := 16;
		SPIKE:		 natural := 304
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
end AVA;

-- architecture body --
architecture AVA_arch of AVA is

constant	sqrtDelay:		natural									:=16;
signal 	dt:				float32;
signal 	stim:				float32;
signal 	v1:				float32;
signal	Vm:				float32;
signal	Ap:				float32;
signal 	stim_last:		float32;
signal 	qAux:				std_logic_vector((ADDR_WIDTH-1) downto 0):=(others =>'0');
signal 	ct:				natural									:=0;
signal 	count:			natural									:=0;
signal	rst_flag: 		std_logic								:='0';
signal	conf_flag:		std_logic 								:='0';
signal	compute_flag:	std_logic 								:='0';
signal 	cycles:			std_logic_vector (15 downto 0)   :=(others=>'0');
signal 	timestamp:		natural									:=0;
signal	K1:				float32;
signal 	q:					float32;
signal	K2:				float32;
signal 	countRK:			natural									:=0;
signal	rk_flag:			std_logic 								:='0';

		--- process ---
BEGIN
	process(clk, reset, v1, rk_flag)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			Vm<=to_float(-30.0,Vm);
			conf_flag<='0';
			ct<=0;
			count<=0;
			rst_flag<='0';
			cycles<=(others =>'0');
			timestamp<=0;
			compute_flag<='0';
			we<='0';
			data<=(others => '0');
			waddr<=(others => '0');
			queue<=(others =>'0');
			qAux<=(others =>'0');
			stim_last<=to_float(0.0,stim_last);
			stim<=to_float(0.0,stim);
		else
			
			if data_ready='1' and result=x"FF" and ct=0 and conf_flag='0' then
				ct<=ct+1;
			elsif data_ready='1' and ct=1 then
				cycles(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=2 then
				cycles(7 downto 0)<=result;
				ct<=ct+1;
			elsif ct=3 then
				ct<=0;
				conf_flag<='1';
			else
				-- nothing happens
			end if;
			
			if data_ready='1' and result=x"EE" and ct=0 then
				rst_flag<='1';
			elsif rst_flag='1' then
				rst_flag<='0';
			else
				-- nothing happens.
			end if;
			
			if conf_flag='1' and timestamp < cycles and count=0 then
				stim_last<=stim;
				if (timestamp>=50 and timestamp<=1000) then
					stim<=to_float(20.0,stim);
				else
					stim<=to_float(0.0,stim);
				end if;
				count<=count+1;
				
			elsif count=1 then
				if stim<to_float(0.0,stim) or stim>to_float(0.0,stim) then
					compute_flag<='1';
					count<=count+1;
				else
					Ap<=to_float(0.0,Ap);
					count<=4;
				end if;
				
			elsif count=2 then
				compute_flag<='0';
				count<=count+1;
			
			elsif count=3 and rk_flag='1' then 
				Ap<=to_float(2.35,Ap)*v1+Vm;
				count<=count+1;

			elsif count=4 then
				we<='1';
				queue<=qAux+1;
				waddr<=qAux;
				qAux<=qAux+1;
				data(55 downto 40)<=std_logic_vector(to_unsigned(timestamp,16));
				data(39 downto 8)<=to_slv(Ap);
				data(7 downto 0)<=(others =>'0');
				count<=count+1;
				
			elsif count=5 then
				we<='0';
				count<=0;
				timestamp<=timestamp+1;
				debug<=std_logic_vector(to_unsigned(timestamp,8));
				
			else
			-- nothing happens
			end if;
			
			rst<=rst_flag;
		end if;	
		else
			-- nothing happens
		end if;
	end process;
	
	process(clk, reset, compute_flag, stim, stim_last)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			dt<=to_float(0.025,dt);
			v1<=to_float(0.0,v1);
			countRK<=0;
			rk_flag<='0';
			K1<=to_float(0.0,K1);
			K2<=to_float(0.0,K2);
			q<=to_float(0.0,q);
		else
			if countRK=0 and compute_flag='1' then
				-- -1.2*x+I(t0)
				K1<=to_float(-1.2,K1)*v1+stim_last;
				countRK<=countRK+1;
				
			elsif countRK=1 then
				countRK<=countRK+1;
				q<=v1+K1*dt;
				
			elsif countRK=2 then
				K2<=to_float(-1.2,K1)*q+stim;
				countRK<=countRK+1;
				
			elsif countRK=3 then
				v1<=v1+K2*to_float(0.05,v1);
				countRK<=countRK+1;
				rk_flag<='1';
				
			elsif countRK=4 then
				rk_flag<='0';
				countRK<=0;
			else
				--nothing happens
			end if;
		end if;
	else
		-- nothing happens
	end if;
	end process;
end AVA_arch;
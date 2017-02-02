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

entity AMM is

generic 
	(
		DATA_WIDTH : natural := 56;
		ADDR_WIDTH : natural := 32;
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
end AMM;

-- architecture body --
architecture AMM_arch of AMM is

signal 	A:					float32;
signal 	dt:				float32;
signal 	stim:				float32;
signal 	stim_last:		float32;
signal 	v1:				float32;
signal	forces:			float32;
signal	forces_aux:		float32;
signal	tau1:				float32;
signal	tauc:				float32;
signal	spikeTrain:		std_logic_vector (SPIKE-1 downto 0)	:=(others=>'0');
signal 	qAux:				std_logic_vector((ADDR_WIDTH-1) downto 0):=(others =>'0');
signal 	ct:				natural									:=0;
signal 	count:			natural									:=0;
signal	rst_flag: 		std_logic								:='0';
signal	conf_flag:		std_logic 								:='0';
signal	compute_flag:	std_logic 								:='0';
signal	spike_flag:		std_logic 								:='0';
signal 	cycles:			std_logic_vector (15 downto 0)   :=(others=>'0');
signal 	timestamp:		natural									:=0;
signal	K1:				float32;
signal 	q:				float32;
signal	K2:				float32;
signal	Cn:				float32;
signal 	countRK:			natural									:=0;
signal	rk_flag:			std_logic 								:='0';
signal	aux:				std_logic_vector (31 downto 0)   :=(others=>'0');

function train2spk(spikeTrain: std_logic_vector (SPIKE-1 downto 0)) return std_logic_vector is
	variable spikes: std_logic_VECTOR(15 downto 0) := (others =>'0');
	begin
		for I in 0 to SPIKE-1 loop
			if spikeTrain(i)='1' then
				spikes:=x"0001";
			else
				-- do nothing
			end if;
		end loop;
		return spikes;
	end train2spk;

		--- process ---
BEGIN
	process(clk, reset, v1, rk_flag)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			A<=to_float(0.0,A);
			dt<=to_float(0.0,dt);
			tau1<=to_float(0.0,tau1);
			tauc<=to_float(0.0,tauc);
			forces<=to_float(0.0,forces);
			forces_aux<=to_float(0.0,forces_aux);
			conf_flag<='0';
			ct<=0;
			count<=0;
			rst_flag<='0';
			cycles<=(others =>'0');
			timestamp<=0;
			spikeTrain<=(others =>'0');
			compute_flag<='0';
			spike_flag<='0';
			we<='0';
			data<=(others => '0');
			waddr<=(others => '0');
			queue<=(others =>'0');
			qAux<=(others =>'0');
			aux<=(others=>'0');
		else
			
			if data_ready='1' and result=x"FF" and ct=0 and conf_flag='0' then
				ct<=ct+1;
			elsif data_ready='1' and ct=1 then
				cycles(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=2 then
				cycles(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=3 then
				aux(31 downto 24)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=4 then
				aux(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=5 then
				aux(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=6 then
				aux(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=7 then
				A<=to_float(aux,A);
				aux(31 downto 24)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=8 then
				aux(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=9 then
				aux(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=10 then
				aux(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=11 then
				tau1<=to_float(aux,tau1);
				aux(31 downto 24)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=12 then
				aux(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=13 then
				aux(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=14 then
				aux(7 downto 0)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=15 then
				tauc<=to_float(aux,tauc);
				aux(31 downto 24)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=16 then
				aux(23 downto 16)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=17 then
				aux(15 downto 8)<=result;
				ct<=ct+1;
			elsif data_ready='1' and ct=18 then
				aux(7 downto 0)<=result;
				ct<=ct+1;
			elsif ct=19 then
				dt<=to_float(aux,dt);
				ct<=0;
				conf_flag<='1';
			else
				-- nothing happens
			end if;

			if data_ready='1' and result=x"FD" and ct=0 and conf_flag='1' and spike_flag='0' then
				ct<=ct+1;
			elsif data_ready='1' and ct>0 and ct<39 then
				spikeTrain((SPIKE-1-(ct-3)*8) downto (SPIKE-8-(ct-3)*8))<=result;
				ct<=ct+1;
			elsif ct=39 then
				ct<=0;
				spike_flag<='1';
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
			
			if conf_flag='1' and timestamp < cycles and count=0 and spike_flag='1' then
				compute_flag<='1';
				count<=count+1;
			
			elsif count=1 then
				compute_flag<='0';
				count<=count+1;
			
			elsif count=2 and rk_flag='1' then 
				forces<=v1;
				count<=count+1;

			elsif count=3 then
				we<='1';
				queue<=qAux+1;
				waddr<=qAux;
				qAux<=qAux+1;
				data(55 downto 40)<=std_logic_vector(to_unsigned(timestamp,16));
				data(39 downto 8)<=to_slv(forces);
				data(7 downto 0)<=(others =>'0');
				count<=count+1;
				
			elsif count=4 then
				we<='0';
				count<=0;
				timestamp<=timestamp+1;		
				spike_flag<='0';
			else
			-- nothing happens
			end if;
			debug<=std_logic_vector(to_unsigned(timestamp,8));
			rst<=rst_flag;
		end if;	
		else
			-- nothing happens
		end if;
	end process;
	
	process(clk, reset, compute_flag, timestamp, A, dt, tau1, tauc)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			stim<=to_float(0.0,stim);
			v1<=to_float(0.0,v1);
			countRK<=0;
			rk_flag<='0';
			K1<=to_float(0.0,K1);
			K2<=to_float(0.0,K2);
			q<=to_float(0.0,q);
			Cn<=to_float(0.0,Cn);
			stim_last<=to_float(0.0,stim_last);
		else
			if countRK=0 and compute_flag='1' then
				if timestamp>=100 and timestamp<=600 then
					stim<=to_float(unsigned(train2spk(spikeTrain)),stim);
				else
					stim<=(others =>'0');
				end if;
				countRK<=countRK+1;
			
			elsif countRK=1 then
				K1<=-Cn/tauc+stim_last;
				countRK<=countRK+1;
				
				
			elsif countRK=2 then
				countRK<=countRK+1;
				q<=Cn+K1*dt;
				
			elsif countRK=3 then
				K2<=-q/tauc+stim;
				countRK<=countRK+1;
				
			elsif countRK=4 then
				Cn<=Cn+K2*to_float(0.05,Cn);
				K1<=-v1/tau1;
				countRK<=countRK+1;
				
			elsif countRK=5 then
				K1<=K1+A*Cn;
				countRK<=countRK+1;
				
			elsif countRK=6 then
				q<=v1+K1*dt;
				K2<=A*Cn;
				countRK<=countRK+1;
				
			elsif countRK=7 then
				K2<=-q/tau1+K2;
				countRK<=countRK+1;
				
			elsif countRK=8 then
				v1<=v1+K2*to_float(0.05,Cn);
				countRK<=countRK+1;
				rk_flag<='1';
				
			elsif countRK=9 then
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
end AMM_arch;

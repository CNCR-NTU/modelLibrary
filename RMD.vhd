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

entity RMD is

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
		exp_res 	: IN	STD_LOGIC_VECTOR (31 downto 0);
		exp_oflw	: IN std_logic;
		exp_nan	: IN std_logic;
		exp_zero	: IN std_logic;
		abs_res 	: IN	STD_LOGIC_VECTOR (31 downto 0);
		waddr		: OUT std_logic_vector((ADDR_WIDTH-1) downto 0);
		data		: OUT std_logic_vector((DATA_WIDTH-1) downto 0);
		we			: OUT std_logic;
		queue		: out std_logic_vector((ADDR_WIDTH-1) downto 0);
		rst		: OUT std_logic;
		exp_data	: out	STD_LOGIC_VECTOR (31 downto 0);
		abs_data	:  out		STD_LOGIC_VECTOR (31 downto 0);
		debug		: OUT std_logic_vector (7 downto 0)
		);
end RMD;

-- architecture body --
architecture RMD_arch of RMD is

constant	expDelay:		natural									:=17;
signal 	A:					float32;
signal 	B:					float32;
signal 	C:					float32;
signal 	D:					float32;
signal 	m:					float32;
signal 	dt:				float32;
signal 	stim:				float32;
signal 	v1:				float32;
signal	Vm:				float32;
signal	Vm2:				float32;
signal	Vm1:				float32;
signal	Ap:				float32;
signal 	stim_last:		float32;
signal 	stim1_last:		float32;
signal	step:				float32;
signal	x:					float32;
signal	x1:				float32;
signal	x2:				float32;
signal	aux1:				float32;
signal	aux2:				float32;
signal	aux3:				float32;
signal	iflag:			std_logic 								:='0';
signal	exp_flag:		std_logic 								:='0';
signal	aux4:				float32;
signal	aux5:				float32;
signal	aux6:				float32;
signal	s:					natural									:=0;
signal	state:			integer									:=0;
signal 	qAux:				std_logic_vector((ADDR_WIDTH-1) downto 0):=(others =>'0');
signal 	ct:				natural									:=0;
signal 	count:			natural									:=0;
signal	rst_flag: 		std_logic								:='0';
signal	conf_flag:		std_logic 								:='0';
signal	compute_flag:	std_logic 								:='0';
signal 	cycles:			std_logic_vector (15 downto 0)   :=(others=>'0');
signal 	timestamp:		natural									:=0;
signal	K1:				float32;
signal 	q:				float32;
signal	K2:				float32;
signal 	countRK:			natural									:=0;
signal	rk_flag:			std_logic 								:='0';

		--- process ---
BEGIN
	process(clk, reset, v1, rk_flag)
	variable ct1: natural :=0;
	variable auxi: float32;
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			A<=to_float(0.0,A);
			B<=to_float(0.0,B);
			C<=to_float(126.66,C);
			D<=to_float(0.0,D);
			m<=to_float(0.0,m);
			Vm1<=to_float(-70.0,Vm1);
			Vm2<=to_float(-35.0,Vm2);
			Vm<=to_float(0.0,Vm);
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
			step<=to_float(0.05,step);
			x<=to_float(0.0,x);
			x1<=to_float(0.0,x1);
			x2<=to_float(0.0,x2);
			s<=0;
			state<=0;
			abs_data<=(others =>'0');
			aux1<=to_float(0.0,aux1);
			aux5<=to_float(0.0,aux5);
			aux4<=to_float(0.0,aux4);
			aux6<=to_float(0.0,aux6);
			auxi:=to_float(0.0,auxi);
			iflag<='0';
			ct1:=0;
			exp_flag<='0';
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
			
			if ct1>1 and exp_flag='1' then
				ct1:=ct1-1;
			elsif ct1=1 and exp_flag='1' then
				ct1:=ct1-1;
				exp_flag<='0';
			else
				-- nothing happens
			end if;
			
			if conf_flag='1' and timestamp < cycles and count=0 then
				stim_last<=stim;
				if (timestamp>=100 and timestamp<=500) then
					stim<=to_float(10.0,stim);
				elsif (timestamp>=800 and timestamp<=1000) then
					stim<=to_float(-10.0,stim);
				else
					stim<=to_float(0.0,stim);
				end if;
				
				if timestamp=0 then
					Ap<=Vm1;
					Vm<=Vm2;
					s<=0;
					x<=to_float(0.0,x);
					stim_last<=to_float(0.0,stim_last);
				else
						-- nothing happens
				end if;
				
				count<=count+1;
				
			elsif count=1 then
				if stim<to_float(0.0,stim) or stim>to_float(0.0,stim) then
					iflag<='0';
					--d = 7.851e-5/(1.711e-6+exp(-2.258*I(t)))+0.1244
					--D = d-70*(abs(I(t))+I(t))/(2*I(t))-Vm*(abs(I(t))-I(t))/(2*I(t))
					exp_data<=to_slv(to_float(2.0,Ap)*stim);
					exp_flag<='1';
					D<=to_float(0.1244,D);
					aux1<=to_float(1.711e-6,aux1);
					aux4<=to_float(7.851e-5,aux4);
					aux5<=to_float(2.0,aux5)*stim;
					aux6<=to_float(-70.0,aux6);
					abs_data<=to_slv(stim);
					ct1:=expDelay;
				else
					iflag<='1';
					x<=to_float(0.0,x);
					if stim<stim_last or stim>stim_last then
						s<=0;
					else
						--nothing happens
					end if;
					if Ap>=Vm2 then
						aux4<=Vm2-Ap;
					elsif Ap<Vm2 then
						aux4<=Vm1-Ap;
					end if;
				end if;
				count<=count+1;
					
				
					
			
			elsif count=2 then
				if iflag='1' then
					auxi:=to_float(-0.001,auxi)*to_float(s,auxi);
					exp_data<=to_slv(auxi);
					exp_flag<='1';
					aux1<=to_float(1.0,aux1);
					ct1:=expDelay;
				else
					x2<=to_float(abs_res,x2)/aux5-stim/aux5;
					x1<=to_float(abs_res,x1)/aux5+stim/aux5;
					if Vm=Vm2 then
						m<=to_float(0.93,m);
					else
						m<=to_float(0.4,m);
					end if;
				end if;
				count<=count+1;
				
			elsif count=3 then
				aux6<=aux6*x1;
				aux1<=aux1*x2;
				count<=count+1;
				
			elsif count=4 then
				D<=D+aux6+aux1;
				A<=to_float(-0.3341,A)*x1/aux5;
				aux1<=m*x2/aux5;
--				a=(0.04166/(0.0179+exp(-0.7376*I(t))))+0.3341
--				A = -a*(abs(I(t))+I(t))/(2*I(t))+m*(abs(I(t))-I(t))/(2*I(t))
				count<=count+1;
			
			elsif count=5 then
				A<=A+aux1;
--				b=0.04*(1.103*I(t)**2-4.518*I(t)+14.84)/(I(t)**2-15.28*I(t)+79.42)
--				B=b*(abs(I(t))+I(t))/(2*I(t))-0.04*(abs(I(t))-I(t))/(2*I(t))
				aux1<=stim*stim;
				B<=to_float(-0.04,B)*x2;
				aux6<=to_float(-4.518,aux6)*stim+to_float(14.84,aux6);
				count<=count+1;
			
			elsif count=6 then
				aux1<=aux1+to_float(79.42,aux1)+to_float(-15.28,aux1)*stim;
				aux6<=to_float(0.04412,aux6)*aux1+aux6;
				count<=count+1;
			
			elsif count=7 then
				aux1<=aux6/aux1;
				count<=count+1;
			
			elsif count=8 then
				B<=aux1*x1+B;
				count<=count+1;
			-- missing:
			-- a=(0.04166/(0.0179+exp(-0.7376*I(t))))
			-- d = 7.851e-5/(1.711e-6+exp(-2.258*I(t)))
				
			elsif count=3 and exp_flag='0' then
				if iflag='0' and rk_flag='1' then
					--  V[t+1] = C(t)*x + D(t)
					compute_flag<='1';
					count<=count+1;
					x<=aux1+to_float(exp_res,x);
					
				else
					if exp_flag='0' then
						aux1<=aux1+to_float(exp_res,aux1);
						aux4<=to_float(0.1,Ap)*aux4;
					else
						-- nothing happens
					end if;
				end if;
				count<=count+1;
			
				
			elsif count=3 then
				if iflag='0' then
					compute_flag<='0';
					count<=count+1;
				else
					Ap<=aux4+aux5+Ap+aux6;
					count<=5;
				end if;
			
			elsif count=4 and rk_flag='1' then 
				Ap<=C*v1+D;
				if stim>2 then
					state<=state-1;
					s<=s+1;
					aux1<=to_float(0.0125,aux1)*to_float(s,aux1);
				else
					aux1<=to_float(0.0,aux1);
				end if;	
				count<=count+1;
			
			elsif count=5 then
				Ap<= Ap+aux1;
				count<=count+1;

			elsif count=6 then
				we<='1';
				queue<=qAux+1;
				waddr<=qAux;
				qAux<=qAux+1;
				data(55 downto 40)<=std_logic_vector(to_unsigned(timestamp,16));
				data(39 downto 8)<=to_slv(Ap);
				data(7 downto 0)<=(others =>'0');
				count<=count+1;
				
			elsif count=7 then
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
	
	process(clk, reset, compute_flag, stim, stim_last, exp_res, exp_nan, exp_nan, exp_oflw, exp_zero)
	variable ct: natural :=0;
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
			aux2<=to_float(0.00,aux2);
			aux3<=to_float(0.00,aux3);
			exp_data<=(others =>'0');
			ct:=0;
		else
			if countRK=0 and compute_flag='1' then
				aux2<=to_float(-0.8,aux2)*v1;
				aux3<=to_float(0.064,aux3)/stim1_last;
				exp_data<=to_slv(stim);
				ct:=0;
				countRK<=countRK+1;
			
			elsif countRK=1 then
				if ct<=expDelay then
					ct:=ct+1;
				else
					if exp_nan='0' and exp_oflw='0' and exp_zero='0' then
						K1<=aux2+aux3/to_float(exp_res,K1);
						aux3<=aux3/to_float(exp_res,aux3);
						countRK<=countRK+1;
						ct:=0;
					else
						--ERROR! Stop
						K1<=aux2+aux3/to_float(exp_res,K1);
						aux3<=aux3/to_float(exp_res,aux3);
						countRK<=countRK+1;
						ct:=0;
					end if;
				end if;
				
			elsif countRK=2 then
				countRK<=countRK+1;
				q<=v1+K1*dt;
				
			elsif countRK=3 then
				aux2<=to_float(-0.8,aux2)*q;
				aux3<=to_float(0.064,aux3)/stim;
				countRK<=countRK+1;
				
			elsif countRK=4 then
				K2<=aux2+aux3;
				countRK<=countRK+1;
				
			elsif countRK=5 then
				v1<=v1+K2*to_float(0.05,v1);
				countRK<=countRK+1;
				rk_flag<='1';
				
			elsif countRK=6 then
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
end RMD_arch;

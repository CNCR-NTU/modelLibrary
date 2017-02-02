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

entity ASER is

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
		sqrt_res : IN	STD_LOGIC_VECTOR (31 downto 0);
		abs_res 	: IN	STD_LOGIC_VECTOR (31 downto 0);
		waddr		: OUT std_logic_vector((ADDR_WIDTH-1) downto 0);
		data		: OUT std_logic_vector((DATA_WIDTH-1) downto 0);
		we			: OUT std_logic;
		queue		: out std_logic_vector((ADDR_WIDTH-1) downto 0);
		rst		: OUT std_logic;
		sqrt_data: out	STD_LOGIC_VECTOR (31 downto 0);
		abs_data:  out		STD_LOGIC_VECTOR (31 downto 0);
		debug		: OUT std_logic_vector (7 downto 0)
		);
end ASER;

-- architecture body --
architecture ASER_arch of ASER is

constant	sqrtDelay:		natural									:=16;
signal 	C:					float32;
signal 	D:					float32;
signal 	dt:				float32;
signal 	stim:				float32;
signal 	i:					float32;
signal 	v1:				float32;
signal	Vm:				float32;
signal	Ap:				float32;
signal	Ap_last:			float32;
signal 	stim_last:		float32;
signal 	stim1_last:		float32;
signal	step:				float32;
signal	x:					float32;
signal	aux1:				float32;
signal	aux2:				float32;
signal	aux3:				float32;
signal	iflag:			std_logic 								:='0';
signal	aux4:				float32;
signal	aux5:				float32;
signal	aux6:				float32;
signal	t1:				float32;
signal	state:			integer									:=0;
signal 	qAux:				std_logic_vector((ADDR_WIDTH-1) downto 0):=(others =>'0');
signal 	ct:				natural									:=0;
signal 	count:			natural									:=0;
signal 	icount:			natural									:=0;
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
signal	aux:				std_logic_vector (31 downto 0)   :=(others=>'0');

		--- process ---
BEGIN
	process(clk, reset, v1, rk_flag, abs_res)
	begin
	if clk'event and clk='1' then 
		if reset='1' then
			Ap<=to_float(0.00,Ap);
			Ap_last<=to_float(0.00,Ap_last);
			C<=to_float(0.0,C);
			D<=to_float(0.0,D);
			Vm<=to_float(0.0,Vm);
			conf_flag<='0';
			ct<=0;
			count<=0;
			icount<=500;
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
			stim1_last<=to_float(0.0,stim1_last);
			stim<=to_float(0.0,stim);
			step<=to_float(0.0,step);
			x<=to_float(0.00,x);
			i<=to_float(0.00,i);
			t1<=to_float(0.00,t1);
			state<=0;
			abs_data<=(others =>'0');
			aux1<=to_float(0.00,aux1);
			aux5<=to_float(0.00,aux5);
			aux4<=to_float(0.00,aux4);
			aux6<=to_float(0.00,aux6);
			iflag<='0';
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
				Vm<=to_float(aux,Vm);
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
				C<=to_float(aux,C);
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
			elsif ct=15 then
				step<=to_float(aux,step);
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
				stim1_last<=stim;
				if (timestamp>=100 and timestamp<=600) or (timestamp>=1200 and timestamp<=1700) or (timestamp>=2300 and timestamp<=2800) then
					stim<=to_float(4.0,stim);
				else
					stim<=to_float(0.0,stim);
				end if;
				Ap_last<=Ap;
				Ap<=Vm;
				if timestamp=0 then
					x<=to_float(0.0,x);
					t1<=to_float(1.0,t1);
					stim<=to_float(0.0,stim);
					stim_last<=to_float(0.0,stim_last);
				else
						-- nothing happens
				end if;
				
				count<=count+1;
				
			elsif count=1 then
				if icount=500 then
					stim_last<=to_float(0.0,stim_last);
					state<=0;
					t1<=to_float(1.0,t1);
				else
					stim_last<=stim_last+stim;
				end if;
				if stim<stim1_last or stim>stim1_last or stim<to_float(0.0,stim) or stim>to_float(0.0,stim) then
					state<=state+1;
				else
					-- nothing happens
				end if;
				if stim<to_float(0.0,stim) or stim>to_float(0.0,stim) then
					i<=stim;
					iflag<='0';
					if state>1 then
						D<=Vm;
					else
						--D=Vm/2. - Vm/2.*(abs(I(t))-I(t))/(2*I(t))
						abs_data<=to_slv(stim);
						aux4<=to_float(2.0,aux4)*stim;
						D<=Vm/to_float(2.0,D);
					end if;
					count<=count+1;
				else
					iflag<='1';
					if stim>stim1_last or stim<stim1_last then
						t1<=to_float(0.00,t1);
						x<=to_float(0.0,x);
					else
						-- do nothing
					end if;
					if Ap_last>Vm and state<3 then
						--V[t+1]=-7.292*x**3+3.635*x**2-5.13*x-25.6/i-0.008*I_prev
						Ap<=to_float(-25.6,Ap)/i;
						aux4<=to_float(-7.292,aux4)*x;
						aux5<=x*x;
						aux6<=to_float(-0.008,aux6)*stim_last+to_float(-5.13,aux6)*x;
						count<=count+1;
					else
						x<=to_float(0.0,x);
						count<=6; -- jump to tx data
					end if;
				end if;
					
			
			elsif count=2 then
				if iflag='0' then
					if state<=1 then
						aux5<=to_float(abs_res,D)-stim;
					else
						-- nothing happens
					end if;
					compute_flag<='1';
				else
					aux5<=to_float(3.635,aux5)*aux5;
					aux4<=aux4*aux5;
				end if;
				count<=count+1;
			
				
			elsif count=3 then
				if iflag='0' then
					if state<=1 then
						D<=D+D*aux5/aux4;
					else
						-- nothing happens
					end if;
					count<=count+1;
					compute_flag<='0';
				else
					Ap<=aux4+aux5+Ap+aux6;
					x<=x+step;
					count<=6; -- jump to tx data
				end if;
			
			elsif count=4 and rk_flag='1' then 
				Ap<=C*v1+D;
				if stim>2 and iflag='0' then
					state<=state-1;
					t1<=t1+to_float(1.0,t1);
					aux1<=to_float(0.0125,aux1)*t1;
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
				if stim=to_float(0.0,stim) then
					icount<=icount+1;
				else
					icount<=0;
				end if;
				
			else
			-- nothing happens
			end if;
			
			rst<=rst_flag;
		end if;	
		else
			-- nothing happens
		end if;
	end process;
	
	process(clk, reset, compute_flag, stim, stim1_last, sqrt_res, abs_res)
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
			sqrt_data<=(others =>'0');
			ct:=0;
		else
			if countRK=0 and compute_flag='1' then
				aux2<=to_float(-0.8,aux2)*v1;
				aux3<=to_float(0.064,aux3)*stim1_last;
				sqrt_data<=abs_res;
				ct:=0;
				countRK<=countRK+1;
			
			elsif countRK=1 then
				if ct<=sqrtDelay then
					ct:=ct+1;
				else
					K1<=aux2+aux3/to_float(sqrt_res,K1);
					aux3<=stim/to_float(sqrt_res,aux3);
					ct:=0;
				end if;
				countRK<=countRK+1;
				
			elsif countRK=2 then
				countRK<=countRK+1;
				aux3<=to_float(0.064,aux3)*aux3;
				q<=v1+K1*dt;
				
			elsif countRK=3 then
				aux2<=to_float(-0.8,aux2)*q;
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
end ASER_arch;

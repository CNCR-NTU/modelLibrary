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

entity AMMpaper is

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
end AMMpaper;

-- architecture body --
architecture AMMpaper_arch of AMMpaper is

signal 	A:					float32;
signal 	dt:				float32;
signal 	stim:				float32;
signal 	stim_last:		float32;
signal 	v1:				float32;
signal	forces:			float32;
signal	forces_aux:		float32;
signal	tau1:				float32;
signal	tauc:				float32;
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
signal	Cn:				float32;
signal 	countRK:			natural									:=0;
signal	rk_flag:			std_logic 								:='0';
signal	aux:				std_logic_vector (31 downto 0)   :=(others=>'0');

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
			compute_flag<='0';
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
			
			if data_ready='1' and result=x"EE" and ct=0 then
				rst_flag<='1';
			elsif rst_flag='1' then
				rst_flag<='0';
			else
				-- nothing happens.
			end if;
			
			if conf_flag='1' and timestamp < cycles and count=0 then
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
			v1<=to_float(0.0,v1);
			countRK<=0;
			rk_flag<='0';
			K1<=to_float(0.0,K1);
			K2<=to_float(0.0,K2);
			q<=to_float(0.0,q);
			Cn<=to_float(0.0,Cn);
			stim<=to_float(0.0,stim);
			stim_last<=to_float(0.0,stim_last);
		else
			if countRK=0 and compute_flag='1' then
				stim_last<=stim;
				if (timestamp>=512 and timestamp<=520) or (timestamp>=526 and timestamp<=527) or (timestamp>=529 and timestamp<=530)or timestamp=532 or timestamp=610 or (timestamp>=628 and timestamp<=634) or (timestamp>=976 and timestamp<=977) or timestamp=979 or (timestamp>=1481 and timestamp<=1484) or timestamp=1487 then
					stim<=to_float(5.595454545,stim);
					
				elsif (timestamp>=521 and timestamp<=525) or timestamp=528 or timestamp=531 or (timestamp>=636 and timestamp<=640) or (timestamp>=714 and timestamp<=718) or (timestamp>=761 and timestamp<=762) or timestamp=764 or (timestamp>=830 and timestamp<=831) or (timestamp>=858 and timestamp<=859) or (timestamp>=861 and timestamp<=863) or (timestamp>=880 and timestamp<=881) or timestamp = 883 or (timestamp>=918 and timestamp<=922) or (timestamp>=946 and timestamp<=950) or (timestamp>=956 and timestamp<=957) or timestamp=1055 or timestamp=1057 or (timestamp>=1063 and timestamp<=1064) or timestamp = 1068 or (timestamp>=1145 and timestamp<=1150) or (timestamp>=1246 and timestamp<=1247) or (timestamp>=1269 and timestamp<=1270) or (timestamp>=1297 and timestamp<=1301) or timestamp=1304 or (timestamp>=1341 and timestamp<=1342) or (timestamp>=1344 and timestamp<=1346) or (timestamp>=1372 and timestamp<=1375) or (timestamp>=1410 and timestamp<=1414) or timestamp=1480 then
					stim<=to_float(1.0,stim);
					
				elsif (timestamp>=562 and timestamp<=568) or (timestamp>=570 and timestamp<=571) or (timestamp>=660 and timestamp<=665) or timestamp=668 or (timestamp>=765 and timestamp<=768) or timestamp = 771 or (timestamp>=813 and timestamp<=819) or (timestamp>=878 and timestamp<=879) or timestamp = 882 or (timestamp>=951 and timestamp<=955) or timestamp = 958 or (timestamp>=1047 and timestamp<=1054) or timestamp = 1056 or (timestamp>=1077 and timestamp<=1083) or (timestamp>=1178 and timestamp<=1184) or (timestamp>=1243 and timestamp<=1244) or timestamp=1248 or (timestamp>=1279 and timestamp<=1286) or (timestamp>=1336 and timestamp<=1337) or (timestamp>=1339 and timestamp<=1340) or timestamp=1343 or (timestamp>=1369 and timestamp<=1370) or (timestamp>=1380 and timestamp<=1386) or (timestamp>=1419 and timestamp<=1425) or (timestamp>=1469 and timestamp<=1470)then
					stim<=to_float(4.795454545,stim);
					
				elsif timestamp=569 or timestamp=573 or (timestamp>=1347 and timestamp<=1348) or timestamp=1351 then
					stim<=to_float(1.8,stim);
					
				elsif timestamp=572 or timestamp=574 or (timestamp>=1464 and timestamp<=1468) or timestamp=1471 then
					stim<=to_float(2.545454545,stim);
					
				elsif timestamp=576 or timestamp=1185 or timestamp=1200 or timestamp=1390 or timestamp=1426 then
					stim<=to_float(0.8,stim);
					
				elsif (timestamp>=581 and timestamp<=585) or (timestamp>=690 and timestamp<=694) or (timestamp>=731 and timestamp<=732) or timestamp = 734 or (timestamp>=706 and timestamp<=712) or (timestamp>=799 and timestamp<=803) or (timestamp>=908 and timestamp<=915) or timestamp = 917 or (timestamp>=980 and timestamp<=984) or (timestamp>=1017 and timestamp<=1021) or (timestamp>=1103 and timestamp<=1108) or (timestamp>=1227 and timestamp<=1232) or (timestamp>=1235 and timestamp<=1239) or timestamp=1242  or (timestamp>=1305 and timestamp<=1308) or (timestamp>=1352 and timestamp<=1356) then
					stim<=to_float(2.345454545,stim);
				elsif (timestamp>=586 and timestamp<=590) or (timestamp>=670 and timestamp<=671) or timestamp=675 or (timestamp>=1116 and timestamp<=1120) or timestamp=1123 or (timestamp>=1195 and timestamp<=1199) then
					stim<=to_float(5.25,stim);
					
				elsif (timestamp>=591 and timestamp<=597) or (timestamp>=602 and timestamp<=609) or timestamp=611 or (timestamp>=706 and timestamp<=712) or (timestamp>=723 and timestamp<=730) or timestamp = 733 or (timestamp>=723 and timestamp<=730) or timestamp = 733 or timestamp=771 or (timestamp>=765 and timestamp<=768) or timestamp = 832 or (timestamp>=871 and timestamp<=877) or (timestamp>=937 and timestamp<=943) or (timestamp>=1035 and timestamp<=1039) or (timestamp>=1059 and timestamp<=1062) or timestamp=1065 or (timestamp>=1090 and timestamp<=1096) or (timestamp>=1126 and timestamp<=1130) or (timestamp>=1169 and timestamp<=1170) or (timestamp>=1172 and timestamp<=1173) or timestamp=1175 or (timestamp>=1211 and timestamp<=1215) or (timestamp>=1302 and timestamp<=1303) or (timestamp>=1331 and timestamp<=1335) or timestamp=1338 or (timestamp>=1451 and timestamp<=1455) or (timestamp>=1472 and timestamp<=1479) then
					stim<=to_float(2.0,stim);	
					
				elsif (timestamp>=598 and timestamp<=601) or (timestamp>=1240 and timestamp<=1241) or timestamp=1245 or (timestamp>=1349 and timestamp<=1350) then
					stim<=to_float(3.0,stim);
					
				elsif timestamp=626 or timestamp=722 or timestamp=843 or timestamp=897 or timestamp=1033 or timestamp=1087 or timestamp=1194 or timestamp=1208 or timestamp=1329 or timestamp=1450 then
					stim<=to_float(0.345454545,stim);
					
				elsif (timestamp>=666 and timestamp<=667) or timestamp=669 or timestamp=672 or (timestamp>=845 and timestamp<=849) or (timestamp>=864 and timestamp<=868)  or (timestamp>=964 and timestamp<=975) or timestamp=978 or (timestamp>=1066 and timestamp<=1067)  or (timestamp>=1069 and timestamp<=1071) or (timestamp>=1164 and timestamp<=1168) or timestamp=1171 or (timestamp>=1364 and timestamp<=1368) or timestamp=1371 or (timestamp>=1444 and timestamp<=1449) then
					stim<=to_float(1.545454545,stim);
					
				elsif (timestamp>=673 and timestamp<=674) or timestamp=676 or (timestamp>=776 and timestamp<=777) or (timestamp>=825 and timestamp<=829) or (timestamp>=1012 and timestamp<=1016) or (timestamp>=1262 and timestamp<=1268) or timestamp=1271 or (timestamp>=1439 and timestamp<=1443) or (timestamp>=1485 and timestamp<=1486) then
					stim<=to_float(3.345454545,stim);
					
				elsif (timestamp>=769 and timestamp<=770) or (timestamp>=772 and timestamp<=774) then
					stim<=to_float(5.795454545,stim);
					
				elsif timestamp=775 or timestamp=778 then
					stim<=to_float(2.795454545,stim);
					
				elsif (timestamp>=804 and timestamp<=808) or (timestamp>=1022 and timestamp<=1026) or (timestamp>=1272 and timestamp<=1276) or (timestamp>=1309 and timestamp<=1312) or (timestamp>=1456 and timestamp<=1460) then
					stim<=to_float(3.25,stim);
					
				elsif (timestamp>=853 and timestamp<=857) or timestamp=860 then
					stim<=to_float(6.595454545,stim);
					
				elsif timestamp=916 then
					stim<=to_float(3.595454545,stim);
					
				elsif timestamp=1084 or timestamp=1112 or timestamp=1490 then
					stim<=to_float(-0.454545455,stim);
					
				elsif (timestamp>=1121 and timestamp<=1122) then
					stim<=to_float(6.25,stim);
					
				elsif timestamp=1287 then
					stim<=to_float(0.545454545,stim);
					
				else
					stim<=to_float(0.0,stim);
					
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
end AMMpaper_arch;

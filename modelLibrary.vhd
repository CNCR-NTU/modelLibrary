---------------------------------------------------------
--! @file
--! @brief Model library
-------------------------------------------------------
--! Use standard library
LIBRARY IEEE;
--! Use logic elements
USE  IEEE.STD_LOGIC_1164.all;
--! Use unsigned logic elements
USE  IEEE.STD_LOGIC_UNSIGNED.all;
--! Use numeric elements
use ieee.numeric_std.all;
--! ieee_proposed for VHDL-93 version
--! ieee in the release
use ieee.fixed_float_types.all;
--!ieee_proposed for fixed point
use ieee.fixed_pkg.all;
--!ieee_proposed for floating point
use ieee.float_pkg.all;


entity modelLibrary is
generic(
		WMI				: natural	:= 2560;		--! Neuron model input bus size. WMI=k+WSI+RESERVED, k>WO, k=2048+504+96=2648
		WO					: natural	:= 512;		--! Neuron model output bus size
		WSI				: natural	:= 504; 		--! Synaptic inputs. 
		RESERVED			: natural	:= 104		--! Reserved for timestamp, timestep and neuron model. model (WSI+7 downto WSI), timestamp (WSI+71 downto WSI+8) and time_step (WSI+103 downto WSI+72)
		);
		
port (clk					: IN STD_LOGIC;										--! Clock
		reset					: IN STD_LOGIC; 										--! Reset
		neuronModelIn		: IN	STD_LOGIC_Vector(WMI-1 downto 0);		--! Data to the Neuron model	
		runStep				: IN	std_logic;										--! Run next step
		restoreState		: IN	std_logic;										--! Restore Neuron Model state
		busyNM				: OUT std_logic;										--! Neuron Model Busy
		neuronModelOut		: OUT STD_LOGIC_Vector(WO-1 downto 0);  		--! Neuron Model Output data 
		sendSpike			: OUT std_logic										--! Send spike
		);
end modelLibrary;

--architecture body --
architecture modelLibrary_arch of modelLibrary is


constant synapses	: 		natural				:=2; 	--! number of synapses   
signal 	aV:				float32;
signal 	mR:				float32;
signal	av_past:			float32;
signal	mr_past:			float32;	
signal	spike_aux:		std_logic			:='0';
signal	count:			natural				:=0;
signal	ref:				float32;	
signal 	aux1:				float32;
signal 	aux2:				float32;
signal 	aux3:				float32;
signal 	aux4:				float32;
signal 	aux5:				float32;
signal 	aux6:				float32;
signal 	aux7:				float32;
signal 	aux8:				float32;
signal 	current:			float32;
signal 	time_stepms:	float32;	
signal	busyNM_aux:		std_logic					:='0';			--! Neuron Model Busy


BEGIN			--- process ---
model_library: process (clk, reset)
	variable internalcounter: float32;
	begin
		if rising_edge(clk) then
			if (reset ='1') then
				time_stepms<= to_float(0.0,time_stepms);
				aV<=to_float(2.0,aV);
				mR<=to_float(0.0,mR);
				av_past<=to_float(0.0,av_past);
				mr_past<=to_float(0.0,mr_past);
				aux1<=to_float(0.0,aux1);
				aux2<=to_float(0.0,aux2);
				aux3<=to_float(0.0,aux3);
				aux4<=to_float(0.0,aux4);
				aux5<=to_float(0.0,aux5);
				aux6<=to_float(0.0,aux6);
				aux7<=to_float(0.0,aux7);
				aux8<=to_float(0.0,aux8);
				current<=to_float(0.0,current);
				spike_aux<='0';
				ref<=to_float(0.0,ref);
				count<=0;
				internalcounter:=to_float(0.0,internalcounter);
				busyNM_aux<='0';
			else
				--! RESERVED bits
				--! model neuronModelIn(WSI+7 downto WSI)     						| 8 bits  | 0- No Neuron Model selected, 1- I&F, 2- LIF
				--! timestamp neuronModelIn(WSI+71 downto WSI+8) 					| 64 bits |
				--! time_step neuronModelIn(WSI+103 downto WSI+72)   					| 32 bits | 
				--! RESERVED bits
				--!=============================================================================================================================================
				--! if model = 1 I&F
				--! abs_ref neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0)	   		| 32 bits | absolute refractory period = 5 ms
				--! v_th neuronModelIn(WSI+RESERVED+63 downto WSI+RESERVED+32)				| 32 bits | threshold voltage = 50 mV
				--! v_res neuronModelIn(WSI+RESERVED+95 downto WSI+RESERVED+64) 			| 32 bits | reset voltage = 2 mV
				--! aV neuronModelIn(WSI+RESERVED+127 downto WSI+RESERVED+96) 				| 32 bits | Output neuronModelOut(15 downto 0) | 32 bits |
				--! weight 1 neuronModelIn(WSI+RESERVED+159 downto WSI+RESERVED+128) 			| 32 bits | reset voltage = 1.5 A |
				--! weight 2 neuronModelIn(WSI+RESERVED+191 downto WSI+RESERVED+160) 			| 32 bits | reset voltage = 0.5 A |
				--!=============================================================================================================================================
				--! if model = 2 LIF
				--! abs_ref neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0)			| 32 bits | absolute refractory period = 5 ms
				--! v_th neuronModelIn(WSI+RESERVED+63 downto WSI+RESERVED+32)				| 32 bits | threshold voltage = 50 mV
				--! v_res neuronModelIn(WSI+RESERVED+95 downto WSI+RESERVED+64)			 	| 32 bits | reset voltage = 2 mV
				--! cap neuronModelIn(WSI+RESERVED+127 downto WSI+RESERVED+96)				| 32 bits | capacitance = 1nF
				--! res neuronModelIn(WSI+RESERVED+159 downto WSI+RESERVED+128)				| 32 bits | Leaky resistance = 40 Mohm
				--! aV neuronModelIn(WSI+RESERVED+191 downto WSI+RESERVED+160)				| 32 bits | Output neuronModelOut(15 downto 0) | 32 bits |
				--! weight 1 neuronModelIn(WSI+RESERVED+223 downto WSI+RESERVED+192)		 	| 32 bits | reset voltage = 1.5 A |
				--! weight 2 neuronModelIn(WSI+RESERVED+255 downto WSI+RESERVED+224)			| 32 bits | reset voltage = 0.5 A |
				--!=============================================================================================================================================
				--! if model = 3 Izhikevich
				--! a neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0)				| 32 bits | parameter a = 0.02
				--! b neuronModelIn(WSI+RESERVED+63 downto WSI+RESERVED+32)				| 32 bits | parameter b = 0.2
				--! c neuronModelIn(WSI+RESERVED+95 downto WSI+RESERVED+64)				| 32 bits | parameter c = -65 mV
				--! d neuronModelIn(WSI+RESERVED+127 downto WSI+RESERVED+96)				| 32 bits | parameter d = 8
				--! v_th neuronModelIn(WSI+RESERVED+159 downto WSI+RESERVED+128)			| 32 bits | threshold voltage = 35 mv
				--! ap_past neuronModelIn(WSI+RESERVED+191 downto WSI+RESERVED+160)			| 32 bits | initial action potential = -70 mv
				--! mr_past neuronModelIn(WSI+RESERVED+223 downto WSI+RESERVED+192)			| 32 bits | initial membrane recovery = -14 mv
				--! aV neuronModelIn(WSI+RESERVED+255 downto WSI+RESERVED+224)				| 32 bits | Output neuronModelOut(31 downto 0) | 32 bits |
				--! mR neuronModelIn(WSI+RESERVED+287 downto WSI+RESERVED+256)				| 32 bits | Output neuronModelOut(63 downto 32) | 32 bits |
				--! current 1 neuronModelIn(WSI+RESERVED+319 downto WSI+RESERVED+288)		   	| 32 bits | reset voltage = 1.5 A |
				--! current 2 neuronModelIn(WSI+RESERVED+351 downto WSI+RESERVED+320)			| 32 bits | reset voltage = 0.5 A |
				if restoreState='1' then 
					time_stepms<=to_float(neuronModelIn(WSI+103 downto WSI+72),time_stepms)/to_float(1000.0,time_stepms); -- must be 1
					busyNM_aux<='1';
					if neuronModelIn(WSI+7 downto WSI)=1 then
						ref<=to_float(neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0),ref);
						aV<=to_float(neuronModelIn(WSI+RESERVED+127 downto WSI+RESERVED+96),aV);
					elsif neuronModelIn(WSI+7 downto WSI)=2 then
						ref<=to_float(neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0),ref);
						aV<=to_float(neuronModelIn(WSI+RESERVED+191 downto WSI+RESERVED+160),aV);
					elsif neuronModelIn(WSI+7 downto WSI)=3 then
						aV<=to_float(neuronModelIn(WSI+RESERVED+255 downto WSI+RESERVED+224),aV);
						mR<=to_float(neuronModelIn(WSI+RESERVED+287 downto WSI+RESERVED+256),mR);
						av_past<=to_float(neuronModelIn(WSI+RESERVED+191 downto WSI+RESERVED+160),av_past);
						mr_past<=to_float(neuronModelIn(WSI+RESERVED+223 downto WSI+RESERVED+192),mr_past);
					else
						-- do nothing
					end if;
				else
					-- do nothing
				end if;
				case count is
						when 0 =>
							if runStep='1' and restoreState='0' then
								spike_aux<='0';
								if neuronModelIn(WSI+7 downto WSI)=3 then
									av_past<=aV;
									mr_past<=mR;
								else
									--do nothing
								end if;
								if neuronModelIn(WSI+7 downto WSI)=1 then
									aux1<=to_float(neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0),aux1); -- abs_ref_period
									aux2<=to_float(neuronModelIn(WSI+RESERVED+63 downto WSI+RESERVED+32),aux2); -- v_th
									aux3<=to_float(neuronModelIn(WSI+RESERVED+95 downto WSI+RESERVED+64),aux3); -- v_res
								elsif neuronModelIn(WSI+7 downto WSI)=2 then
									aux1<=to_float(neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0),aux1); -- abs_ref_period
									aux2<=to_float(neuronModelIn(WSI+RESERVED+63 downto WSI+RESERVED+32),aux2); -- v_th
									aux3<=to_float(neuronModelIn(WSI+RESERVED+95 downto WSI+RESERVED+64),aux3); -- v_res
									aux4<=to_float(neuronModelIn(WSI+RESERVED+127 downto WSI+RESERVED+96),aux4); -- cap
									aux5<=to_float(neuronModelIn(WSI+RESERVED+159 downto WSI+RESERVED+128),aux5); -- res
									aux6<=aV*time_stepms; -- av*time_stepms;
									aux7<=to_float(neuronModelIn(WSI+RESERVED+63 downto WSI+RESERVED+32),aux7); -- v_th
									aux8<=to_float(neuronModelIn(WSI+RESERVED+95 downto WSI+RESERVED+64),aux8); -- v_res
								elsif neuronModelIn(WSI+7 downto WSI)=3 then
									aux1<=to_float(neuronModelIn(WSI+RESERVED+159 downto WSI+RESERVED+128),aux1); --v_th
									aux2<=to_float(140.0,aux2);
									aux3<=to_float(5.0,aux3);
									aux4<=to_float(neuronModelIn(WSI+RESERVED+31 downto  WSI+RESERVED+0),aux4); --a
									aux5<=to_float(neuronModelIn(WSI+RESERVED+63 downto WSI+RESERVED+32),aux5); --b
									aux6<=to_float(neuronModelIn(WSI+RESERVED+95 downto WSI+RESERVED+64),aux6); --c
									aux7<=to_float(neuronModelIn(WSI+RESERVED+127 downto WSI+RESERVED+96),aux7); --d
									aux8<=to_float(0.04,aux1);
								else
									-- do nothing
								end if;	

								count<=count+1;
								busyNM_aux<='1';
								for i in 0 to synapses-1 loop
									if neuronModelIn(i)='1' then
										if neuronModelIn(WSI+7 downto WSI)=1 then
											internalcounter:=internalcounter+to_float(neuronModelIn(WSI+RESERVED+i*32+159 downto WSI+RESERVED+i*32+128),aV);
										elsif neuronModelIn(WSI+7 downto WSI)=2 then
											internalcounter:=internalcounter+to_float(neuronModelIn(WSI+RESERVED+i*32+223 downto WSI+RESERVED+i*32+192),aV);
										elsif neuronModelIn(WSI+7 downto WSI)=3 then
											internalcounter:=internalcounter+to_float(neuronModelIn(WSI+RESERVED+i*32+319 downto WSI+RESERVED+i*32+288),aV);
										else
											-- do nothing
										end if;
									else
										-- do nothing
									end if;
								end loop;
							else
								-- do nothing
							end if;
						when 1 =>
							current<=internalcounter;
							if neuronModelIn(WSI+7 downto WSI)=1 or neuronModelIn(WSI+7 downto WSI)=2 then
								if ref > to_float(0.0,ref) then
									ref <= ref-to_float(1.0,ref);
									busyNM_aux<='0';
									count<=3;
									internalcounter:=to_float(0.0,internalcounter);
									aV <= aux3; -- v_res
								elsif aV > aux2 then
									spike_aux<='1';
									ref <=aux1;
									internalcounter:=to_float(0.0,internalcounter);
									count<=3;
									aV<=aux3;
								else
									if neuronModelIn(WSI+7 downto WSI)=1 then 
										aux1<=internalcounter*time_stepms; -- Iapp*ct
										count<=count+1;
									elsif neuronModelIn(WSI+7 downto WSI)=2 then
										aux1<=aux6/(aux4*aux5); -- aV*ct/(res*cap)
										aux2<=current*time_stepms/aux4; -- Iapp*ct/cap
										count<=count+1;
									else
										--do nothing
									end if;
								end if;
							
							elsif neuronModelIn(WSI+7 downto WSI)=3 then
								if aV >= aux1 then
									--av_past<=aux1;
									aV<=aux6;
									mr_past<=mR+aux7;
									spike_aux<='1';
									count<=3;
								else
									aux1<=av_past-mr_past+aux2+current;
									aux2<=time_stepms*av_past*aux8*av_past;
									aux3<=time_stepms*av_past*aux3;
									aux4<=time_stepms*av_past*aux4*aux5;
									aux5<=time_stepms*aux4*mr_past;
									count<=count+1;
									
								end if;

							else
								--do nothing
							end if;
						when 2=>
							if neuronModelIn(WSI+7 downto WSI)=1 then
								aV <= aV+aux1; -- v + Iapp*ct
								count<=count+1;

							elsif neuronModelIn(WSI+7 downto WSI)=2 then
								if (aV+aux2-aux1)>aux8 then
									aV <= aV+aux2-aux1; -- aV+Iapp*ct/c-aV*ct/res/cap
								else
									aV <= aux7;
								end if;
								count<=count+1;
							elsif neuronModelIn(WSI+7 downto WSI)=3 then
								aV<=aux1+aux2+aux3;
								mR<=mr_past+aux4-aux5;
								count<=count+1;
							else
								--do nothing
							end if;
							
						when 3=>
							internalcounter:=to_float(0.0,internalcounter);
							busyNM_aux<='0';
							count<=0;
							aux1<=to_float(0.0,aux1);
							aux2<=to_float(0.0,aux2);
							aux3<=to_float(0.0,aux3);
							aux4<=to_float(0.0,aux4);
							aux5<=to_float(0.0,aux5);
							aux6<=to_float(0.0,aux6);
							aux7<=to_float(0.0,aux7);
							aux8<=to_float(0.0,aux8);
						when others=>
							count<=0;
					end case;
				busyNM<=busyNM_aux;
				neuronModelOut(31 downto 0)<=to_slv(aV);
				neuronModelOut(63 downto 32)<=to_slv(mR);
				neuronModelOut(WO-1 downto 64)<=(others =>'0');
				sendSpike<=spike_aux;
			end if;
		else
			-- do nothing
		end if;
	END PROCESS model_library;
end modelLibrary_arch;
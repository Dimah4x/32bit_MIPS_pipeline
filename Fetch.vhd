--new fetch --47221757

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Fetch is

port(
	clk:in std_logic;
	--inputs
	PCBranchD: in std_logic_vector(31 downto 0);
	Jump: in std_logic;
	StallF:in std_logic;
	StallD:in std_logic;
	PCSrcD:in std_logic;
	--outputs
	InstrD:out std_logic_vector(31 downto 0);
	PCPlus4D:out std_logic_vector(31 downto 0) --PCtoIMEM+4
	);
	
end entity Fetch;

architecture fetch_logic of Fetch is
--signals
signal InstrF:std_logic_vector(31 downto 0);
signal PCtoIMEM:std_logic_vector(31 downto 0);
signal PCtoJMUX:std_logic_vector(31 downto 0);
signal JMUXOut:std_logic_vector(31 downto 0);
signal PCPlus4F:std_logic_vector(31 downto 0):=(others=>'0');

--components
component imem
port(
	pc:    in  std_logic_vector(31 downto 0);
    instr: out std_logic_vector(31 downto 0)
	);
end component;

begin

imem_unit: imem port map( pc=>PCtoIMEM,instr=>InstrF);




PCMUX: process(PCSrcD,PCPlus4F,PCBranchD) is --not sure about this
	begin
		if (PCSrcD = '0') then 
			PCtoJMUX <= PCPlus4F;
		else
			PCtoJMUX <= PCBranchD;
		end if;
	end process;
		
JMUX: process(Jump,PCPlus4F,InstrF,PCtoJMUX) is
	begin
		if (Jump = '1') then 
			JMUXOut <= PCPlus4F(31 downto 28) & InstrF(25 downto 0) & "00";
		else
			JMUXOut <= PCtoJMUX;
		end if;
	end process;
	
stallF_FF: process(clk,StallF) is
	begin
		if StallF = '0' then
			if rising_edge(clk) then
			
				PCtoIMEM <= JMUXOut;
			end if;
		end if;
	end process;
	
stallD_FF: process(clk,PCSrcD,StallD) is
	begin
		if (PCSrcD='1') then
			PCPlus4D<= x"00000000";
			InstrD<= x"00000000";
		else
			if StallD = '0' then
				if rising_edge(clk) then
				  
					InstrD <= InstrF;
					PCPlus4D <= PCPlus4F;
				end if;
			end if;
		end if;
	end process;
PCPlus4F <= conv_std_logic_vector((conv_integer(PCtoIMEM) + 4),32);
end architecture;
	
	
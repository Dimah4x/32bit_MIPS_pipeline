--47221757
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity WriteBack is
 port ( 
 
		RegWriteW		: in	std_logic;
		WriteRegW		: in	std_logic_vector(4 downto 0);
		MemToRegW      : in  std_logic;
		ReadDataW 		: in  std_logic_vector(31 downto 0); 
		ALUOutW        : in  std_logic_vector(31 downto 0);
		RegWriteWout		: out	std_logic;
		WriteRegWout		: out	std_logic_vector(4 downto 0);
		ResultW        : out std_logic_vector(31 downto 0)
	  
	  
	  );
end entity WriteBack;

architecture arc_WriteBack of WriteBack is
signal RegWriteWout_sig:std_logic;
signal WriteRegWout_sig:std_logic_vector(4 downto 0);
begin -- begin arc 
	
	RegWriteWout_sig<=RegWriteW;
	RegWriteWout<=RegWriteWout_sig;
	WriteRegWout_sig<=WriteRegW;
	WriteRegWout<=WriteRegWout_sig;
	-- define write process to the data memory
	MuxWB: process(MemToRegW,ReadDataW,ALUOutW) is
	begin
		
		if (MemToRegW='1') then
			  ResultW <= ReadDataW;
		elsif (MemToRegW='0') then
			 ResultW  <= ALUOutW;
		else
			ResultW <= (others => '0');
					
    	end if;	
	end process MuxWB; 
	
			
		
end architecture arc_WriteBack;	  
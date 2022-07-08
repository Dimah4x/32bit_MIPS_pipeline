--47221757
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Memory is
 port ( 
		
		clk        : in  std_logic;
		rst        : in  std_logic;
		MemWriteM  : in  std_logic;
		WriteDataM : in  std_logic_vector(31 downto 0);
		MemReadM    : in std_logic; -- beware!!!! we should add in the decode mode a signal MemRead!!!!!
	  -----------MEM-WB REGISTER--------------
		-- MEM-WB register inputs
		RegWriteM        : in  std_logic;
		MemToRegM        : in  std_logic;
		-- ReadDataM        : in  std_logic_vector(31 downto 0); THIS IS AN INTERNAL SIGNAL CALLED :read_data_out !!!!!!!!!!!!
		ALUOutM          : in  std_logic_vector(31 downto 0);
		WriteRegM        : in std_logic_vector(4 downto 0);
		
		--  MEM-WB register outputs
		RegWriteW      : out  std_logic:= '0';
		MemToRegW      : out  std_logic;
		ReadDataW 		: out  std_logic_vector(31 downto 0); 
		ALUOutW        : out  std_logic_vector(31 downto 0);
		WriteRegW      : out std_logic_vector(4 downto 0)
		----------------------------------------------------
	  );
end entity Memory;

architecture arc_Memory of Memory is

signal read_data_out : std_logic_vector(31 downto 0);


component DataMemory is
	port(
		clk        : in  std_logic;
		rst        : in  std_logic;
		address    : in  std_logic_vector(31  downto 0);
		-- write side
		mem_write  : in  std_logic;
		write_data : in  std_logic_vector(31 downto 0);
		-- read side
		mem_read   : in  std_logic;
		read_data  : out std_logic_vector(31 downto 0));	
			
	end component DataMemory;

begin -- begin arc 
	
	DMem: 
			DataMemory port map(
				clk 		 => clk,
				rst			 => rst,
				-- write side
				address	     => ALUOutM , 
				mem_write 	 => MemWriteM, 
				write_data   => WriteDataM,  
				-- read side
				mem_read     => MemReadM, 
				read_data    => read_data_out
				
			);
			
	
	----------------------
	-- !!!!NOTICE!!!!!  The DATA MEMORY Exploits the rising and the falling edge of the clok!!! meaning within 
	-- the same clock it writes and then reads.
	
	-- WRITE = RISING EDGE
	-- READ  = FALLING EDGE
	
	--------------------------------
	
		
	----- DEFINE THE PROCESSES FOR THE MEM-WB REGISTER -----
	
	
		SYNC_MEM_WB:process(clk,rst) 
		begin --asynchronous rst
			if (rst = '1') then
			   RegWriteW   	<= '0';
				MemToRegW   	<= '0';
				ReadDataW		<= (others => '0');
				ALUOutW	   	<= (others => '0');
				WriteRegW		<= "00000";
			
			elsif rising_edge(clk) then -- the register READS, thus the falling edge
			   	RegWriteW		<= RegWriteM;
				MemToRegW		<= MemToRegM;
				ReadDataW		<= read_data_out;
				ALUOutW			<= ALUOutM;
				WriteRegW		<= WriteRegM;
			end if;
		end process; 
	
		
		
		
		
end architecture arc_Memory;	  
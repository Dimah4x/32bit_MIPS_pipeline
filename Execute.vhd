--47221757
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Execute is

port(
	-- generic inputs --
	clk : in std_logic;
	rst: in std_logic; -- input from hazard unit
	--forwarding unit inputs --
	ForwardAE: in std_logic_vector(1 downto 0);
	ForwardBE: in std_logic_vector(1 downto 0);
	-- pipeline registers -- 
	RegWriteE: in std_logic;
	MemToRegE: in std_logic;
	MemWriteE: in std_logic;
	MemReadE : in std_logic;
	ALUControlE: in std_logic_vector(5 downto 0); -- gets rtype_to_funct from decode--
	ALUSrcE: in std_logic;
	RegDstE: in std_logic;
	--inputs from bor--
	RD1E: in std_logic_vector(31 downto 0);
	RD2E: in std_logic_vector(31 downto 0);
	ResultW: in std_logic_vector(31 downto 0);
	ALUoutMfromMem: in std_logic_vector(31 downto 0); --expect fromn memory stage
	--input from instruction decode--
	RsE: in std_logic_vector(4 downto 0);
	RdE: in std_logic_vector(4 downto 0);
	RtE: in std_logic_vector(4 downto 0);
	SignImmE: in std_logic_vector(31 downto 0);
	--register outputs--
	RsEout: out std_logic_vector(4 downto 0);
	RtEout: out std_logic_vector(4 downto 0);
	ALUOutM: out std_logic_vector(31 downto 0);
	WriteDataM: out std_logic_vector(31 downto 0);
	WriteRegM: out std_logic_vector(4 downto 0);
	RegWriteM: out std_logic;
	MemToRegM: out std_logic;
	MemWriteM: out std_logic;
	MemReadM: out std_logic
	);
end entity;


architecture execute_logic of execute is
-- inner signals --
signal ALUOutMsig: std_logic_vector(31 downto 0);
signal ALUOutE: std_logic_vector(31 downto 0);
signal SrcAE: std_logic_vector(31 downto 0);
signal SrcBE: std_logic_vector(31 downto 0);
signal WriteDataE: std_logic_vector(31 downto 0);
signal WriteRegE: std_logic_vector(4 downto 0);
signal ALUcont: std_logic_vector(3 downto 0);

component SmallEgg is
	port(
		funct: in std_logic_vector(5 downto 0);
		ALUop: out std_logic_vector(3 downto 0));
	end component SmallEgg;

begin

tinyegg: SmallEgg port map(funct=>ALUControlE, ALUop=>ALUcont); -- ALUControlE gets rtype_to_funct from decode--
RsEout<=RsE;
RtEout<=RtE;

WriteRegE<= RtE when RegDstE='0' else RdE;
	    
--MuxRegDST: process(RegDstE,RdE,RtE) is
	--begin
	--	if (RegDstE='1') then
	--		  WriteRegE <= RdE;
	--	else 
	--		 WriteRegE  <= RtE;		
    --	end if;	
--end process MuxRegDST; 

MuxForwardAE: process(ForwardAE,ResultW,clk) is
	begin
	
		if (ForwardAE = "00") then
			  SrcAE <= RD1E;
		elsif (ForwardAE = "01") then
			 SrcAE  <= ResultW;	
		elsif (ForwardAE = "10") then
			 SrcAE  <= ALUoutMfromMem;
		else
			 SrcAE  <= (others => '0');
    	end if;	
end process MuxForwardAE; 

MuxForwardBE: process(ForwardBE,ResultW,clk) is
	begin
		if (ForwardBE = "00") then
			  WriteDataE <= RD2E;
		elsif (ForwardBE = "01") then
			 WriteDataE  <= ResultW;	
		elsif (ForwardBE = "10") then
			 WriteDataE  <= ALUoutMfromMem;
		else
			 WriteDataE  <= (others => '0');
    	end if;	
end process MuxForwardBE;

MuxALUSrc: process(ALUSrcE,SignImmE,WriteDataE) is
	begin
		if (ALUSrcE='1') then
			  SrcBE <= SignImmE;
		else 
			 SrcBE  <= WriteDataE;		
    	end if;	
end process MuxALUSrc;

process(ALUcont,SrcAE,SrcBE) is
begin
	if (ALUcont = "0000") then
		ALUOutE <= (SrcAE and SrcBE);
	elsif (ALUcont = "0001") then
		ALUOutE <= (SrcAE or SrcBE);
	elsif (ALUcont = "0010") then
		ALUOutE <= conv_std_logic_vector(conv_integer(SrcAE) + conv_integer(SrcBE),32); -- might not work
	elsif (ALUcont = "0110") then
		ALUOutE <= conv_std_logic_vector(conv_integer(SrcAE) - conv_integer(SrcBE),32); -- might not work
	elsif (ALUcont = "0111") then
		if conv_integer(SrcAE)>conv_integer(SrcBE) then	-- might not work
			ALUOutE(31 downto 1) <= (others => '0');
			ALUOutE(0) <= '1';
		else
	 		ALUOutE <= (others => '0');
	 	end if;
	elsif (ALUcont = "1100") then
		ALUOutE<= (SrcAE nor SrcBE);
	else
		ALUOutE  <= (others => '0');
	end if;
end process;

--ALUoutE <= 		SrcAE+SrcBE when ALUcont = "0010" else
--				SrcAE-SrcBE when ALUcont = "0110" else
--				SrcAE and SrcBE when ALUcont = "0000" else
	--			SrcAE or SrcBE when ALUcont = "0001" else
	--			SrcAE nor SrcBE when ALUcont = "1100" else
	--			SrcAE+SrcBE;

SYNC_MEM_WB:process(clk,rst) 
	begin --asynchronous rst
		if (rst = '1') then
			RegWriteM 	<= '0';
			MemToRegM 	<= '0';
			MemWriteM 	<= '0';
			ALUOutM		<= (others => '0');
			WriteRegM	<= (others => '0');
			WriteDataM	<= (others => '0');
			MemReadM	<= '0';
			
		elsif rising_edge(clk) then -- the register READS, thus the falling edge
			RegWriteM	<= RegWriteE;
			MemToRegM	<= MemToRegE;
			MemWriteM	<= MemWriteE;
			ALUOutM		<= ALUOutE;
			WriteRegM	<= WriteRegE;
			WriteDataM	<= WriteDataE;
			MemReadM	<= MemReadE;
			
		end if;
	end process; 
end execute_logic;

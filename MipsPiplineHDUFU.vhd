library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MipsPiplineHDUFU is
port(clk: in std_logic;
	rst:in std_logic
	);
end entity MipsPiplineHDUFU;


architecture MipsPiplineHDUFU_logic of MipsPiplineHDUFU is

--------------------------------------------------------------------
component Fetch is 
	port(
		clk: in std_logic;
		PCBranchD: in std_logic_vector(31 downto 0);
		Jump: in std_logic;
		StallF:in std_logic;
		StallD:in std_logic; --stalls from interlock
		PCSrcD:in std_logic; --flushD
		InstrD:out std_logic_vector(31 downto 0);
		PCPlus4D:out std_logic_vector(31 downto 0)
	);
end component Fetch;

--------------------------------------------------------------------
	
component Decode is 
	port(
	clk:in std_logic;
	rst:in std_logic;
	--inputs from left to right
	InstrD: in std_logic_vector(31 downto 0);
	PCPlus4D:in std_logic_vector(31 downto 0);
	ResultW:in std_logic_vector(31 downto 0);
	WriteRegW:in std_logic_vector(4 downto 0);
	RegWriteW:in std_logic;
--	ForwardAD:in std_logic;
--	ForwardBD:in std_logic;
	FlushE:in std_logic;
	ALUOutM:in std_logic_vector(31 downto 0);
	--outputs from left to right
	RegWriteE:out std_logic;
	MemToRegE:out std_logic;
	MemWriteE:out std_logic;
	MemReadE:out std_logic;
	ALUControlE: out std_logic_vector(5 downto 0); --gets R_Type_to_functD
	ALUSrcE:out std_logic;
	RegDstE:out std_logic;
	RD1E: out std_logic_vector(31 downto 0);
	RD2E: out std_logic_vector(31 downto 0);
	RsD: out std_logic_vector(4 downto 0); --goes to interlock and HDU 
	RtD: out std_logic_vector(4 downto 0); --goes to interlock and HDU 
	RdD: out std_logic_vector(4 downto 0);
	RsE: out std_logic_vector(4 downto 0);
	RtE: out std_logic_vector(4 downto 0);
	RdE: out std_logic_vector(4 downto 0);
	BranchD:out std_logic;
	SignImmE:out std_logic_vector(31 downto 0);
	jump:out std_logic;
	PCSrcD:out std_logic;
	PCBranchD:out std_logic_vector(31 downto 0)
	);
end component Decode;

--------------------------------------------------------------------

component Execute is 
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
end component Execute; 

--------------------------------------------------------------------

component Memory is 
	port(
	clk        : in  std_logic;
	rst        : in  std_logic;
	MemWriteM  : in  std_logic;
	WriteDataM : in  std_logic_vector(31 downto 0);
	MemReadM   : in std_logic; -- beware!!!! we should add in the decode mode a signal MemRead!!!!!
  -----------MEM-WB REGISTER--------------
	-- MEM-WB register inputs
	RegWriteM  : in  std_logic;
	MemToRegM  : in  std_logic;
	-- ReadDataM        : in  std_logic_vector(31 downto 0); THIS IS AN INTERNAL SIGNAL CALLED :read_data_out !!!!!!!!!!!!
	ALUOutM    : in  std_logic_vector(31 downto 0);
	WriteRegM  : in std_logic_vector(4 downto 0);
	--  MEM-WB register outputs
	RegWriteW  : out  std_logic;
	MemToRegW  : out  std_logic;
	ReadDataW  : out  std_logic_vector(31 downto 0); 
	ALUOutW    : out  std_logic_vector(31 downto 0);
	WriteRegW  : out std_logic_vector(4 downto 0)
	----------------------------------------------------
	);
end component Memory; 

--------------------------------------------------------------------

component WriteBack is 
	port(
	RegWriteW		: in	std_logic;
	WriteRegW		: in	std_logic_vector(4 downto 0);
	MemToRegW       : in  	std_logic;
	ReadDataW 		: in  	std_logic_vector(31 downto 0); 
	ALUOutW         : in  	std_logic_vector(31 downto 0);
	WriteRegWout	: out	std_logic_vector(4 downto 0);
	RegWriteWout	: out	std_logic;
	ResultW         : out 	std_logic_vector(31 downto 0)
	);
end component WriteBack; 

--------------------------------------------------------------------

component ForwardUnit is 
	port(
	WriteRegM: in std_logic_vector(4 downto 0);
	WriteRegW: in std_logic_vector(4 downto 0);
	RegWriteM: in std_logic;
	RegWriteW: in std_logic;
	RsE: in std_logic_vector(4 downto 0);
	RtE: in std_logic_vector(4 downto 0);
	--forwarding unit outputs --
	ForwardAE: out std_logic_vector(1 downto 0);
	ForwardBE: out std_logic_vector(1 downto 0)
	);
end component ForwardUnit; 

--------------------------------------------------------------------

component HazardUnit is 
	port(
	--HazardUnit inputs --
	RegWriteE: in std_logic;
	MemToRegE: in std_logic; -- ID/EX.MemRead. --> identifies LW 
	MemReadE:  in std_logic;
	RtD: in std_logic_vector(4 downto 0);
	RtE: in std_logic_vector(4 downto 0);
	RsD: in std_logic_vector(4 downto 0);
	--HazardUnit outputs --
	StallF: out std_logic;
	StallD: out std_logic;
	FlushE: out std_logic
	);
end component HazardUnit;

--------------------------------------------------------------------
--general clock signal
signal clk_sig: std_logic;
signal rst_sig: std_logic;
--signals for FETCH
-- signals from Fetch to Decode----------- 
signal jumpDF: 		std_logic;
signal PCSrcDF: 	std_logic; --FlushD
signal InstrDF: 	std_logic_vector(31 downto 0);
signal PCPlus4DF: 	std_logic_vector(31 downto 0);
signal PCBranchDF: 	std_logic_vector(31 downto 0);
-- signals from Fetch to HDU----------- 
signal StallD_HDU: 	std_logic;
signal StallF_HDU: 	std_logic;
--signals for DECODE
--signals from decode to execute
signal RegWriteED: std_logic;
signal MemToRegED: std_logic;
signal MemWriteED: std_logic;
signal MemReadED: std_logic;
signal ALUControlED:  std_logic_vector(5 downto 0); --gets R_Type_to_functD
signal ALUSrcED: std_logic;
signal RegDstED: std_logic;
signal RsED:  std_logic_vector(4 downto 0);
signal RtED:  std_logic_vector(4 downto 0);
signal RdED:  std_logic_vector(4 downto 0);
signal RD1ED:  std_logic_vector(31 downto 0);
signal RD2ED:  std_logic_vector(31 downto 0);
signal SignImmED: std_logic_vector(31 downto 0);
--signal from writeback to decode
signal WriteRegWD: std_logic_vector(4 downto 0);
signal ResultWD:	std_logic_vector(31 downto 0);
signal RegWriteWD: std_logic;
--signals from memory to decode
signal ALUOutMD: std_logic_vector(31 downto 0);
--signals from forward unit to decode
signal ForwardAD_FU: std_logic:='0';
signal ForwardBD_FU: std_logic:='0';
signal ForwardAE_FU: std_logic_vector(1 downto 0);
signal ForwardBE_FU: std_logic_vector(1 downto 0);
signal BranchD_FU: std_logic; --branch predict not implemented
--signals from interlock to decode
signal FlushE_HDU:std_logic;
signal RsD_HDU: std_logic_vector(4 downto 0); --goes to interlock and HDU 
signal RtD_HDU: std_logic_vector(4 downto 0); --goes to interlock and HDU 
--signals from execute to memory
signal ALUOutEM:  std_logic_vector(31 downto 0);
signal WriteDataEM:  std_logic_vector(31 downto 0);
signal WriteRegEM:  std_logic_vector(4 downto 0);
signal RegWriteEM:  std_logic;
signal MemToRegEM:  std_logic;
signal MemWriteEM:  std_logic;
signal MemReadEM:  std_logic;
--signals from memory to writeback
signal RegWriteMW:std_logic;
signal MemToRegMW:std_logic;
signal ReadDataMW: std_logic_vector(31 downto 0);
signal ALUOutMW: std_logic_vector(31 downto 0);
signal WriteRegMW:std_logic_vector(4 downto 0);
signal RsEout_FU:  std_logic_vector(4 downto 0);
signal RtEout_FU:  std_logic_vector(4 downto 0);

begin -- begin arch
------------------------------Port maps------------------------------------------
InsFETCH: Fetch port map(
	--from fetch to decode
	Jump		=>jumpDF,
	clk			=>clk_sig,
	PCBranchD	=>PCBranchDF,
	PCPlus4D	=>PCPlus4DF,
	PCSrcD		=>PCSrcDF,
	InstrD		=>InstrDF,
	--from fetch to HDU
	StallD		=>StallD_HDU,
	StallF		=>StallF_HDU
	);

InsDECODE: Decode port map(
	--from decode to fetch
	clk => clk_sig,
	rst => rst_sig,
	jump => jumpDF,
	PCBranchD => PCBranchDF,
	PCPlus4D=>PCPlus4DF,
	InstrD => InstrDF,
	PCSrcD =>PCSrcDF,
	--from decode to execute
	RegWriteE=>RegWriteED,
	MemToRegE=>MemToRegED,
	MemWriteE=>MemWriteED,
	MemReadE=>MemReadED,
	ALUControlE=>ALUControlED,
	ALUSrcE=>ALUSrcED,
	RegDstE=>RegDstED,
	RsE=>RsED,
	RtE=>RtED,
	RdE=>RdED,
	RD1E=>RD1ED,
	RD2E=>RD2ED,
	SignImmE=>SignImmED,
	--from decode to memory
	ALUOutM=>ALUOutEM,
	--from decode to hazard
	RsD=>RsD_HDU,
	RtD=>RtD_HDU,
	--from decode to forward
--	ForwardAD=>ForwardAD_FU,
--	ForwardBD=>ForwardBD_FU,
	BranchD=>BranchD_FU, --branch prediction not implemented
	--from decode to interlock
	FlushE=>FlushE_HDU,
	--from decode to writeback
	WriteRegW=>WriteRegWD,
	ResultW=>ResultWD,
	RegWriteW=>RegWriteWD
	);
	
InsEXECUTE: Execute port map(
	clk=>clk_sig,
	rst=>rst_sig,
	ForwardAE=>ForwardAE_FU,
	ForwardBE=>ForwardBE_FU,
	RegWriteE=>RegWriteED,
	MemToRegE=>MemToRegED,
	MemWriteE=>MemWriteED,
	MemReadE=>MemReadED,
	ALUControlE=>ALUControlED,
	ALUSrcE=>ALUSrcED,
	RegDstE=>RegDstED,
	RD1E=>RD1ED,
	RD2E=>RD2ED,
	ResultW=>ResultWD,
	ALUoutMfromMem=>ALUOutEM,
	RsE=>RsED,
	RdE=>RdED,
	RtE=>RtED,
	RsEout=>RsEout_FU,
	RtEout=>RtEout_FU,
	ALUOutM=>ALUOutEM,
	WriteDataM=>WriteDataEM,
	WriteRegM=>WriteRegEM,
	RegWriteM=>RegWriteEM,
	MemToRegM=>MemToRegEM,
	MemWriteM=>MemWriteEM,
	MemReadM=>MemReadEM,
	SignImmE=>SignImmED
	);

InsMEMORY: Memory port map(
	clk=>clk_sig,
	rst=>rst_sig,
	MemWriteM=>MemWriteEM,
	WriteDataM=>WriteDataEM,
	MemReadM=>MemReadEM,
	RegWriteM=>RegWriteEM,
	MemToRegM=>MemToRegEM,
	ALUOutM=>ALUOutEM,
	WriteRegM=>WriteRegEM,
	RegWriteW=>RegWriteMW,
	MemToRegW=>MemToRegMW,
	ReadDataW=>ReadDataMW,
	ALUOutW=>ALUOutMW,
	WriteRegW=>WriteRegMW
	);
	
InsWRITEBACK: WriteBack port map(
	RegWriteWout=>RegWriteWD,
	RegWriteW=>RegWriteMW,
	WriteRegW=>WriteRegMW,
	MemToRegW=>MemToRegMW,
	ReadDataW=>ReadDataMW,
	WriteRegWout=>WriteRegWD,
	ALUOutW=>ALUOutMW,
	ResultW=>ResultWD
	);
	
InsFORWARDUNIT: ForwardUnit port map(
	WriteRegM=>WriteRegMW,
	WriteRegW=>WriteRegWD,
	RegWriteM=>RegWriteEM,
	RegWriteW=>RegWriteWD,
	RsE=>RsEout_FU,
	RtE=>RtEout_FU,
	ForwardAE=>ForwardAE_FU,
	ForwardBE=>ForwardBE_FU
	);
	
InsHAZARDUNIT: HazardUnit port map(
	StallF=>StallF_HDU,
	StallD=>StallD_HDU,
	FlushE=>FlushE_HDU,
	RegWriteE=>RegWriteED,
	MemToRegE=>MemToRegED,
	MemReadE=>MemReadED,
	RtD=>RtD_HDU,
	RsD=>RsD_HDU,
	RtE=>RtED
	);
	

	

rst_sig<= rst;
clk_sig <= clk;

-------------------------- end of port maps------------------------------------
end MipsPiplineHDUFU_logic;

--new decode

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Decode is

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
	RsD: out std_logic_vector(4 downto 0);
	RtD: out std_logic_vector(4 downto 0);
	RdD: out std_logic_vector(4 downto 0);
	RsE: out std_logic_vector(4 downto 0);
	RtE: out std_logic_vector(4 downto 0);
	RdE: out std_logic_vector(4 downto 0);
	BranchD:out std_logic;
	SignImmE:out std_logic_vector(31 downto 0);
	jump:out std_logic;
	PCSrcD:out std_logic;
	PCBranchD:out std_logic_vector(31 downto 0));
	
end entity;

architecture decode_logic of Decode is

signal RegWriteD: 			std_logic;
signal MemToRegD: 			std_logic;
signal MemWriteD: 			std_logic;
signal MemReadD: 			std_logic;
signal R_Type_to_functD: 	std_logic_vector(5 downto 0);
signal ALUSrcD: 			std_logic;
signal RegDstD: 			std_logic;
signal RD1D: 				std_logic_vector(31 downto 0);
signal RD2D: 				std_logic_vector(31 downto 0);
signal clk_sig: 			std_logic;
signal rst_sig: 			std_logic;
signal SignImmD:			std_logic_vector(31 downto 0);
--signal shiftSignImmD:		std_logic_vector(31 downto 0);
signal EquaD: 				std_logic;
signal mux1o:				std_logic_vector(31 downto 0);
signal mux2o:				std_logic_vector(31 downto 0);
signal RsD_sig:				std_logic_vector(4 downto 0);
signal RtD_sig:				std_logic_vector(4 downto 0);
signal RdD_sig:				std_logic_vector(4 downto 0);
signal BranchD_sig:			std_logic;
--signal ForwardAD_sig:		std_logic:= '0';
--signal ForwardBD_sig:		std_logic:='0';

component bor is 
	port(
		clk        : in  std_logic;
		rst        : in  std_logic;
		-- write side
		reg_write  : in  std_logic;
		write_reg  : in  std_logic_vector(4  downto 0);
		write_data : in  std_logic_vector(31 downto 0);
		-- read side
		read_reg1  : in  std_logic_vector(4  downto 0);
		read_data1 : out std_logic_vector(31 downto 0);
		read_reg2  : in  std_logic_vector(4  downto 0);
		read_data2 : out std_logic_vector(31 downto 0)
		);		
end component bor;
	
	
component ControlUnit is 
	port(
		--inputs
		OP :in 	std_logic_vector(5 downto 0);
		funct: in std_logic_vector(5 downto 0);
		--outputs
		jump: out std_logic;
		RegWriteD: out std_logic;
		MemToRegD: out std_logic;
		MemWriteD: out std_logic;
		MemReadD : out std_logic;
		--ALUControlD: out std_logic_vector(3 downto 0);
		ALUSrcD: out std_logic;
		RegDstD: out std_logic;
		BranchD: out std_logic;
		R_Type_to_funct: out std_logic_vector(5 downto 0) -- Because the small egg is inside the execute stage, we need to check if R_Type function is envoked. if so, we read the funct value for the ALUControl 
		);		
end component ControlUnit;

begin

------------------------------Port maps------------------------------------------
RegFile: bor port map(
	clk 		 => clk,
	rst			 => rst,
	-- write side
	reg_write	 => RegWriteW , -- A3 in scheme
	write_reg 	 => WriteRegW, -- enable  write
	write_data   => ResultW,   -- WD3 in scheme
	-- read side
	read_reg1    => InstrD(25 downto 21), -- A1 in scheme
	read_data1   => RD1D,
	read_reg2    => InstrD(20 downto 16), -- A2 in scheme
	read_data2   => RD2D 
);
			
	
CtrlUnit: ControlUnit port map(
	OP 		   			=> InstrD  (31 downto 26),
	funct	   			=> InstrD  (5 downto 0),
	jump	   			=> jump ,
	RegWriteD  			=> RegWriteD, 
	MemToRegD  			=> MemToRegD,   
	MemWriteD  			=> MemWriteD,
	MemReadD   			=> MemReadD,
	ALUSrcD    			=> ALUSrcD,
	RegDstD    			=> RegDstD, 
	BranchD    			=> BranchD_sig, 
	R_Type_to_funct   	=> R_Type_to_functD
);
------------------------------ end if port maps------------------------------------

SignImmD <=  X"0000" & InstrD(15 downto 0) when InstrD(15) = '0' else -- pad with 16 zeros --should be moved to process
				 X"FFFF" & InstrD(15 downto 0);  -- pad with 1 if the number sign is negative (1)
--shiftSignImmD<=SignImmD(29 downto 0) & "00"; 
PCBranchD(31 downto 0) <= (PCPlus4D + (SignImmD(29 downto 0) & "00"));
RsD<=InstrD(25 downto 21);
RtD<=InstrD(20 downto 16);
RdD<=InstrD(15 downto 11);
RsD_sig<=InstrD(25 downto 21);
RtD_sig<=InstrD(20 downto 16);
RdD_sig<=InstrD(15 downto 11);
EquaD<= '1' when mux1o=mux2o else '0';
BranchD<= BranchD_sig;
PCSrcD<= '1' when BranchD_sig = '1' and EquaD = '1' else '0';

--first_mux_bhv: process (ForwardAD_sig) is
--	begin
--	if (ForwardAD_sig = '0') then
		mux1o <= RD1D;
--	else 
--		mux1o <= ALUOutM;
--	end if;
--end process	first_mux_bhv;

--second_mux_bhv: process (ForwardBD_sig) is
--	begin
--	if (ForwardBD_sig = '0') then
		mux2o <= RD2D;
--	else 
--		mux2o <= ALUOutM;
--	end if;
--end process	second_mux_bhv;

--SYNC_ID_EX:process(clk,FlushE) 
SYNC_ID_EX:process(clk,FlushE,RegWriteD ,MemToRegD ,MemWriteD ,MemReadD ,RegDstD ,ALUSrcD)
	begin --asynchronous rst
		if (FlushE = '0') then
			RegWriteE 	<= '0';
			MemToRegE 	<= '0';
			MemWriteE 	<= '0';
			MemReadE	<= '0';
			ALUSrcE	    <= '0';
			RegDstE	    <= '0';
			ALUControlE <= (others => '0');
			RD1E		<= (others => '0');
			RD2E		<= (others => '0');
			RsE			<= (others => '0');
			RtE			<= (others => '0');
			RdE			<= (others => '0');
			--SignImmD    <= (others => '0');
			SignImmE<= (others => '0');
		
		--elsif rising_edge(clk) then -- the register READS, thus the falling edge
		elsif rising_edge(clk) then
			RegWriteE 	<= RegWriteD;
			MemToRegE 	<= MemToRegD;
			MemWriteE 	<= MemWriteD;
			MemReadE    <= MemReadD;
			ALUSrcE	    <= ALUSrcD;
			RegDstE	    <= RegDstD;
			RD1E		<= RD1D;
			RD2E		<= RD2D;
			RsE			<= RsD_sig;
			RtE			<= RtD_sig;
			RdE			<= RdD_sig;
			--if InstrD(15)= '1' then
			--	SignImmD    <= x"1111" & InstrD(15 downto 0);
			--else
			--	SignImmD    <= x"0000" & InstrD(15 downto 0);
			--end if;
			SignImmE<= SignImmD;
			ALUControlE <= R_Type_to_functD;
			
			
			
		end if;
	end process; 
end architecture;
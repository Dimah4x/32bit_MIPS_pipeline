--decode

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ControlUnit is
port(
	--inputs
	OP :in std_logic_vector(5 downto 0);
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
	BranchD: out std_logic; --branch predict not implemented
	R_Type_to_funct: out std_logic_vector(5 downto 0) -- Because the small egg is inside the execute stage, we need to check if R_Type function is envoked. if so, we read the funct value for the ALUControl 
	);
end ControlUnit;

architecture ControlUnit_logic of ControlUnit is
signal R_Type:std_logic; 	--opcode:000000 funct:
signal LW:std_logic; 		--opcode:100011 funct:
signal SW:std_logic; 		--opcode:101011 funct:
signal BEQ:std_logic;		--opcode:000100 funct:
signal ADDI:std_logic;		--opcode:001111 funct: -- load imm 
signal J:std_logic;	 		--opcode:000010 funct:
--signal BNE:std_logic;		--opcode:000101 funct:
--signal SRL:std_logic; this is rtype



begin

-- check opcode and assert logic to function--
R_Type 		<= 	'1' when OP = "000000" else '0' ;--opcode: 000000 funct:
LW			<=	'1' when OP = "100011" else '0' ;--opcode: 100011 funct:
SW			<=	'1' when OP = "101011" else '0';--opcode: 101011 funct:
BEQ			<=	'1' when OP = "000100" else '0';--opcode: 000100 funct:
ADDI		<=	'1' when OP = "001000" else '0';--opcode: 001111 funct:
J	 		<= 	'1' when OP = "000010" else '0';--opcode: 000010 funct:
--BNE		<=	'1' when OP = "000101" else '0';--opcode: 000101 funct:


-- Set control paths according to the type of function recieved--
jump 		<= J;
RegWriteD 	<= R_Type or LW or ADDI;
MemToRegD 	<= LW;
MemWriteD 	<= SW;
MemReadD  	<= LW; 
--ALUControlD <= ????"10"??? when  R_Type='1' else  -- should this signal be here or at the ALU control in execute stage?
		--	   "0010" when  LW='1'     else
		--	   "0010" when  SW='1'     else
		--	   "0110" when  BEQ='1'    else
		--	   "0110" when  BNE='1' ; 
			   
ALUSrcD 				<= LW or SW or ADDI;
RegDstD 				<= R_Type;
BranchD 				<= BEQ;
R_Type_to_funct 		<= funct  	 when   R_Type = '1'    		else   	--replaces ALUControlD
						   "100000"  when  (LW = '1' or SW = '1' or ADDI = '1')  else  	-- In LW and SW we need to use ADD function, thus "100000" is sent to the funct value
						   "100010"  when   BEQ = '1'             	else		-- In BEQ we need to use SUB function, thus "100010" is sent to the funct value
						   (others=>'0');

end architecture;




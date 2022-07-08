--execute control unit (small egg) --47221757

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity SmallEgg is
port(
	funct: in std_logic_vector(5 downto 0);
	ALUop: out std_logic_vector(3 downto 0));
end entity;

architecture small_egg_logic of SmallEgg is

begin
ALUop<= "0010" when funct = "100000" else --add
		"0110" when funct = "100010" else --sub
		"0111" when funct = "101010" else --slt
		"0000" when funct = "100100" else --and
		"0001" when funct = "100101" else --or
		"1100" when funct = "100111" else--nor
		"0000";

end architecture;
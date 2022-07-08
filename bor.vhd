--47221757
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bor is
 port ( 
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
end entity bor;

architecture arc_bor of bor is
type reg_arr is array (natural range <>) of std_logic_vector(write_data'range);
signal regs: reg_arr((2**write_reg'length) -1 downto 0):=
(
0=>x"00000000", 
 1=>x"00000001", 
 2=>x"00000002", 
 3=>x"00000003", 
 4=>x"00000004",
 5=>x"00000005", 
 6=>x"00000006", 
 7=>x"00000007",
 8=>x"00000008", 
 9=>x"00000009",  
 ----------
others=>(others=>'0')
);


begin
	process(clk,rst) is
	begin
		if (rst='1') then
			regs      <=(others=>(others=>'0'));
			read_data1<=(others=>'0');
			read_data2<=(others=>'0');
		elsif rising_edge(clk) then
			if(reg_write='1' and write_reg/="00000") then
			
			regs(conv_integer(write_reg))<=write_data;
			
			end if;
		elsif falling_edge(clk) then	
			read_data1<=regs(conv_integer(read_reg1));
			read_data2<=regs(conv_integer(read_reg2));
    	end if;	
			
	end process; 

end architecture arc_bor;	
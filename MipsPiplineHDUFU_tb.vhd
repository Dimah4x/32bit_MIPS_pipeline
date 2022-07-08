library ieee;
use ieee.std_logic_1164.all;

entity MipsPiplineHDUFU_tb is
end entity MipsPiplineHDUFU_tb;

architecture MipsPiplineHDUFU_logic_tb of MipsPiplineHDUFU_tb is

signal clk: std_logic:='0';
signal rst: std_logic:='0';

--package instructions_pkg is
--begin
-- Forwarding example from page 65 pipline
constant  INSTR_0: std_logic_vector(31 downto 0) := "00000000001000110001000000100010"; --SUB $2,$1,$3;   sub	rd, rs, rt	100010
constant  INSTR_1: std_logic_vector(31 downto 0) := "00000000010001010010000000100100"; --AND $4,$2,$5;   and	rd, rs, rt	100100
constant  INSTR_2: std_logic_vector(31 downto 0) := "00000000100000100010000000100101"; --OR $4,$4,$2;    or	rd, rs, rt	100101
constant  INSTR_3: std_logic_vector(31 downto 0) := "00000000100000100100100000100000"; --ADD $9,$4,$2;   add	rd, rs, rt	100000
-- HazardUnit lw hazard detection example page 74
constant  INSTR_4: std_logic_vector(31 downto 0) := "10001100001000100000000000010100";   --LW $2,20($1); LW $rt,addr($rs) -> |35|rs|rt|addr|
constant  INSTR_5: std_logic_vector(31 downto 0) := "00000000010001010010000000100100"; --AND $4,$2,$5;   and	rd, rs, rt	100100
constant  INSTR_6: std_logic_vector(31 downto 0) := "00000000100000100010000000100111"; --NOR $4,$4,$2;    nor	rd, rs, rt	100111
constant  INSTR_7: std_logic_vector(31 downto 0) := "10101100010000110000000000010101";   --SW $3,21($2); SW $rt,addr($rs) -> |43|rs|rt|addr|
--end instructions_pkg;

component MipsPiplineHDUFU is
port(
		clk: in std_logic;
		rst: in std_logic
	);

end component MipsPiplineHDUFU;


begin -- begin arch

--stimulus : process
--        begin
--	wait for 10 ns;   rst <= '1';
--	wait for 10 ns; rst <='0';
--	wait for 200 ns; 
--end process stimulus;

clock : process
	begin
        wait for 5 ns; clk <= not clk;
end process clock;

uut: MipsPiplineHDUFU
port map(
	clk => clk,
	rst => rst
	);

stim_proc : process
begin
--wait for 10 ns; 
   
wait;
end process stim_proc;

end architecture MipsPiplineHDUFU_logic_tb;


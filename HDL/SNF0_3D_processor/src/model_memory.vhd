-- Quartus II VHDL Template
-- Single-Port ROM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;
use work.model.all;

entity model_memory is
	port (
		clk	: in std_logic;
		addr	: in unsigned(12 downto 0);
		q		: out std_logic_vector(95 downto 0)
	);

end entity;

architecture rtl of model_memory is
	signal rom : mesh_data(MODEL_DATA'length-1 downto 0) := MODEL_DATA;

begin

	process(clk)
	begin
	if(rising_edge(clk)) then
		q <= rom(to_integer(addr));
	end if;
	end process;

end rtl;

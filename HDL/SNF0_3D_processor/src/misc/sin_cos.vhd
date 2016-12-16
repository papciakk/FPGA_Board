library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;

entity sin_cos is
  port(
    clk   : in  std_logic;
    rst   : in  std_logic;
    angle : in  unsigned(8 downto 0);
    sin_out : out signed(15 downto 0);
    cos_out : out signed(15 downto 0)
  );
end entity sin_cos;

architecture arch of sin_cos is
  constant sin_lut : lut(90 downto 0) := gen_sin_lut;
begin 
  process(clk, rst)
  begin
    if (rst = '1') then
      sin_out <= (others => '0');
      cos_out <= (others => '0');
    elsif falling_edge(clk) then
      if angle >= 270 then
        sin_out <= -sin_lut(TO_INTEGER(360 - angle));
        cos_out <= sin_lut(TO_INTEGER(angle - 270));
      elsif angle >= 180 then
        sin_out <= -sin_lut(TO_INTEGER(angle - 180));
        cos_out <= -sin_lut(TO_INTEGER(270 - angle));
      elsif angle >= 90 then
        sin_out <= sin_lut(TO_INTEGER(180 - angle));
        cos_out <= -sin_lut(TO_INTEGER(angle - 90));
      else
        sin_out <= sin_lut(TO_INTEGER(angle));
        cos_out <= sin_lut(TO_INTEGER(90 - angle));
      end if;
    end if;
  end process;
end architecture arch;

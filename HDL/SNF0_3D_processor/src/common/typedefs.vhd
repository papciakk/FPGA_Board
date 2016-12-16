library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

package typedefs is
  subtype byte is unsigned(7 downto 0);
  subtype sint16 is signed(15 downto 0);
  subtype int16 is unsigned(15 downto 0);
  subtype sint32 is signed(31 downto 0);
  subtype int32 is unsigned(31 downto 0);

  type line_3d16_t is record
    x0, y0, z0 : sint16;
    x1, y1, z1 : sint16;
  end record;

  type line_3d32_t is record
    x0, y0, z0 : sint32;
    x1, y1, z1 : sint32;
  end record;

  type mesh_t is array (integer range <>) of line_3d16_t;

  subtype angle_t is unsigned(8 downto 0);
  subtype color10_t is unsigned(9 downto 0);
  subtype vga_pos_t is unsigned(9 downto 0);
  subtype s_vga_pos_t is signed(9 downto 0);
  subtype addr19_t is unsigned(18 downto 0);

  type vram_addr_t is array (1 downto 0) of addr19_t;
  type vram_bit_t is array (1 downto 0) of std_logic;
  type vram_data_t is array (1 downto 0) of std_logic;

  constant KEY_W : integer := 0;
  constant KEY_S : integer := 1;
  constant KEY_A : integer := 2;
  constant KEY_D : integer := 3;
  constant KEY_Q : integer := 4;
  constant KEY_E : integer := 5;
  constant KEY_Z : integer := 6;
  constant KEY_X : integer := 7;

  function to_angle(i : integer) return angle_t;
  function to_byte(i : integer) return byte;

  function extend_to_32_bit(edge16 : line_3d16_t) return line_3d32_t;

  function sel(cond : boolean; opt1 : std_logic; opt2 : std_logic) return std_logic;
  function sel(cond : boolean; opt1 : std_logic_vector; opt2 : std_logic_vector) return std_logic_vector;
  function sel(cond : boolean; opt1 : unsigned; opt2 : unsigned) return unsigned;
  function sel(cond : boolean; opt1 : signed; opt2 : signed) return signed;
  function sel(cond : boolean; opt1 : integer; opt2 : integer) return integer;
  function to_std_logic(cond : boolean) return std_logic;
  
  type lut is array (natural range <>) of signed(15 downto 0);
  function gen_sin_lut return lut;
  
  type str is array (natural range <>) of unsigned(7 downto 0);
  function to_str(s: string) return str;
  
  type mesh_data is array(natural range <>) of std_logic_vector(95 downto 0);
end package typedefs;

package body typedefs is
  function to_str(s: string) return str is
    variable r : str(s'length-1 downto 0) ;
  begin
    for i in 1 to s'high loop
      r(i - 1) := to_unsigned(character'pos(s(i)), 8);
    end loop;
    return r;
  end function;


    function gen_sin_lut return lut is
	   variable slut : lut(90 downto 0);
	 begin
      for i in 0 to 90 loop
	     slut(i) := to_signed(integer(real(8192)*sin(real(i)*0.0174533)), 16);
	   end loop;
	  
	   return slut;
	 end function;

  function sel(cond : boolean; opt1 : std_logic; opt2 : std_logic) return std_logic is
  begin
    if cond then
      return opt1;
    else
      return opt2;
    end if;
  end function;

  function sel(cond : boolean; opt1 : std_logic_vector; opt2 : std_logic_vector) return std_logic_vector is
  begin
    if cond then
      return opt1;
    else
      return opt2;
    end if;
  end function;

  function sel(cond : boolean; opt1 : unsigned; opt2 : unsigned) return unsigned is
  begin
    if cond then
      return opt1;
    else
      return opt2;
    end if;
  end function;

  function sel(cond : boolean; opt1 : signed; opt2 : signed) return signed is
  begin
    if cond then
      return opt1;
    else
      return opt2;
    end if;
  end function;
  
  function sel(cond : boolean; opt1 : integer; opt2 : integer) return integer is
  begin
    if cond then
      return opt1;
    else
      return opt2;
    end if;
  end function;

  function to_std_logic(cond : boolean) return std_logic is
  begin
    if cond then
      return '1';
    else
      return '0';
    end if;
  end function;

  function to_angle(i : integer) return angle_t is
  begin
    return to_unsigned(i, angle_t'length);
  end function;

  function to_byte(i : integer) return byte is
  begin
    return to_unsigned(i, 8);
  end function;

  function extend_to_32_bit(edge16 : line_3d16_t) return line_3d32_t is
    variable edge32 : line_3d32_t;
  begin
    edge32.x0 := resize(edge16.x0, 32);
    edge32.y0 := resize(edge16.y0, 32);
    edge32.z0 := resize(edge16.z0, 32);
    edge32.x1 := resize(edge16.x1, 32);
    edge32.y1 := resize(edge16.y1, 32);
    edge32.z1 := resize(edge16.z1, 32);

    return edge32;
  end function;

end package body;

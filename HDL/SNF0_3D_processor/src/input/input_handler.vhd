library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;

entity input_handler is
  generic(
    rot_x_init  : integer := 90;
    rot_y_init  : integer := 0;
    rot_z_init  : integer := 90;
    scale_init  : integer := 20;
    input_delay : integer := 900
  );

  port(
    rst         : in  std_logic;
	 
    key         : in  std_logic_vector(7 downto 0);
    vga_visible : in  std_logic;
    rot_x       : buffer angle_t   := to_angle(rot_x_init);
    rot_y       : buffer angle_t   := to_angle(rot_y_init);
    rot_z       : buffer angle_t   := to_angle(rot_z_init);
    scale       : buffer byte      := to_byte(scale_init);
    update_rot  : out std_logic := '1'
  );
end entity input_handler;

architecture arch of input_handler is
  signal counter : unsigned(12 downto 0) := (others => '0');
  signal start : std_logic := '1';
begin
  update_rot <= start or 
					 key(KEY_W) or key(KEY_S) or
					 key(KEY_A) or key(KEY_D) or 
					 key(KEY_Q) or key(KEY_E);

  process(vga_visible, rst) is
  begin
    if rst = '1' then
      counter    <= (others => '0');
      rot_x      <= to_angle(rot_x_init);
      rot_y      <= to_angle(rot_y_init);
      rot_z      <= to_angle(rot_z_init);
      scale      <= to_byte(scale_init);
		start	     <= '1';
    elsif rising_edge(vga_visible) then	 
      if counter < input_delay then
        counter <= counter + 1;
      else
        counter <= (others => '0');
		  start <= '0';

        if key(KEY_A) = '1' then
          rot_x <= sel(rot_x < 360, rot_x + 1, to_angle(1));
        end if;
        if key(KEY_D) = '1' then
          rot_x <= sel(rot_x > 0, rot_x - 1, to_angle(360));
        end if;
        if key(KEY_W) = '1' then
          rot_y <= sel(rot_y < 360, rot_y + 1, to_angle(1));
        end if;
        if key(KEY_S) = '1' then
          rot_y <= sel(rot_y > 0, rot_y - 1, to_angle(360));
        end if;
        if key(KEY_Q) = '1' then
          rot_z <= sel(rot_z < 360, rot_z + 1, to_angle(1));
        end if;
        if key(KEY_E) = '1' then
          rot_z <= sel(rot_z > 0, rot_z - 1, to_angle(360));
        end if;
		  if key(KEY_Z) = '1' then
          scale <= sel(scale < 23, scale + 1, to_byte(23));
        end if;
        if key(KEY_X) = '1' then
          scale <= sel(scale > 1, scale - 1, to_byte(1));
        end if;

      end if;
    end if;
  end process;
end architecture arch;






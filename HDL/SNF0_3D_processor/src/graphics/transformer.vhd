library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.typedefs.all;
use work.model.all;

entity transformer is
 
  port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    update_rot     : in  std_logic;
    start          : in  std_logic;
    next_edge      : in  std_logic;
    edge_ready     : out std_logic := '0';
    rendered       : out std_logic := '0';
    rot_x          : in  angle_t;
    rot_y          : in  angle_t;
    rot_z          : in  angle_t;
    scale          : in  signed(31 downto 0);
    x0, y0, x1, y1 : out signed(31 downto 0);
	 LED            : out std_logic_vector(2 downto 0)
  );

end transformer;

architecture arch of transformer is
  type transformer_state is (
    request_sincos_x, get_sincos_x,
    request_sincos_y, get_sincos_y,
    request_sincos_z, get_sincos_z,
    cast_edge_to_32bit,
    apply_x_rot, apply_y_rot, apply_z_rot,
    apply_scale,
    inc_line_cnt,
    edge_draw_wait,
    next_wait
  );

  signal state : transformer_state := next_wait;

  signal edge : line_3d32_t := (others => to_signed(0, 32));
  
  signal start_request      : std_logic := '0';
  signal update_rot_request : std_logic := '1';
  signal next_edge_request  : std_logic := '1';

  signal sin_x, cos_x : sint16;
  signal sin_y, cos_y : sint16;
  signal sin_z, cos_z : sint16;

  signal line_id : unsigned(12 downto 0) := (others => '0');
  signal edge16  : line_3d16_t := (others => to_signed(0, 16));

  signal sin, cos      : sint16;
  signal sin_cos_angle : angle_t;
  
  signal tmp : std_logic_vector(95 downto 0);

begin
  sin_cos : entity work.sin_cos
    port map(
      clk     => clk,
      rst     => rst,
      angle   => sin_cos_angle,
      sin_out => sin,
      cos_out => cos
    );
	 
  model_memory_0 : entity work.model_memory 
    port map(
		clk   => clk,
		addr	=> line_id,
		q		=> tmp
    );
	 
  -- extract coordinates data from memory word
  edge16.x0 <= signed(tmp(1*16-1 downto 0*16));
  edge16.y0 <= signed(tmp(2*16-1 downto 1*16));
  edge16.z0 <= signed(tmp(3*16-1 downto 2*16));
  edge16.x1 <= signed(tmp(4*16-1 downto 3*16));
  edge16.y1 <= signed(tmp(5*16-1 downto 4*16));
  edge16.z1 <= signed(tmp(6*16-1 downto 5*16));
  
  -- convert coordinates to screen space
  x0 <= shift_right(edge.z0, 6) + 320;
  y0 <= shift_right(edge.y0, 6) + 240;
  x1 <= shift_right(edge.z1, 6) + 320;
  y1 <= shift_right(edge.y1, 6) + 240;

  process(clk) is
  begin
    if rising_edge(clk) then
		 update_rot_request <= update_rot;
		 start_request      <= start;
		 next_edge_request  <= next_edge;

		 case state is
			when request_sincos_x =>
			  sin_cos_angle <= rot_x;
			  state    <= get_sincos_x;

			when get_sincos_x =>
			  sin_x      <= sin;
			  cos_x      <= cos;
			  state <= request_sincos_y;

			when request_sincos_y =>
			  sin_cos_angle <= rot_y;
			  state    <= get_sincos_y;

			when get_sincos_y =>
			  sin_y      <= sin;
			  cos_y      <= cos;
			  state <= request_sincos_z;

			when request_sincos_z =>
			  sin_cos_angle <= rot_z;
			  state    <= get_sincos_z;

			when get_sincos_z =>
			  sin_z      <= sin;
			  cos_z      <= cos;
			  edge_ready        <= '0';
			  next_edge_request <= '0';
			  state <= cast_edge_to_32bit;

			when cast_edge_to_32bit =>
			  edge  <= extend_to_32_bit(edge16);
			  state <= apply_x_rot;

			when apply_x_rot =>
			  edge.y0 <= resize(shift_right(edge.y0 * cos_x - edge.z0 * sin_x, 13), 32);
			  edge.z0 <= resize(shift_right(edge.y0 * sin_x + edge.z0 * cos_x, 13), 32);
			  edge.y1 <= resize(shift_right(edge.y1 * cos_x - edge.z1 * sin_x, 13), 32);
			  edge.z1 <= resize(shift_right(edge.y1 * sin_x + edge.z1 * cos_x, 13), 32);
			  state   <= apply_y_rot;

			when apply_y_rot =>
			  edge.x0 <= resize(shift_right(edge.z0 * sin_y + edge.x0 * cos_y, 13), 32);
			  edge.z0 <= resize(shift_right(edge.z0 * cos_y - edge.x0 * sin_y, 13), 32);
			  edge.x1 <= resize(shift_right(edge.z1 * sin_y + edge.x1 * cos_y, 13), 32);
			  edge.z1 <= resize(shift_right(edge.z1 * cos_y - edge.x1 * sin_y, 13), 32);
			  state   <= apply_z_rot;

			when apply_z_rot =>
			  edge.x0 <= resize(shift_right(edge.x0 * cos_z - edge.y0 * sin_z, 13), 32);
			  edge.y0 <= resize(shift_right(edge.x0 * sin_z + edge.y0 * cos_z, 13), 32);
			  edge.x1 <= resize(shift_right(edge.x1 * cos_z - edge.y1 * sin_z, 13), 32);
			  edge.y1 <= resize(shift_right(edge.x1 * sin_z + edge.y1 * cos_z, 13), 32);
			  state   <= apply_scale;

			when apply_scale =>
			  edge.x0 <= resize(edge.x0 + shift_right(edge.x0 * scale, 4), 32);
			  edge.y0 <= resize(edge.y0 + shift_right(edge.y0 * scale, 4), 32);
			  edge.z0 <= resize(edge.z0 + shift_right(edge.z0 * scale, 4), 32);
			  edge.x1 <= resize(edge.x1 + shift_right(edge.x1 * scale, 4), 32);
			  edge.y1 <= resize(edge.y1 + shift_right(edge.y1 * scale, 4), 32);
			  edge.z1 <= resize(edge.z1 + shift_right(edge.z1 * scale, 4), 32);
			  state   <= inc_line_cnt;

			when inc_line_cnt =>
			  if line_id < MODEL_EDGES_NUMBER then
				 line_id    <= line_id + 1;
				 edge_ready <= '1';
				 state <= edge_draw_wait;
			  else
				 line_id    <= (others => '0');
				 rendered   <= '1';
				 state <= next_wait;
			  end if;

			when edge_draw_wait =>
			  if next_edge_request = '1' then
				 state <= cast_edge_to_32bit;
			  end if;

			when next_wait =>
			  if start_request = '1' then
				 start_request <= '0';
				 if update_rot_request = '1' then
					state <= request_sincos_x;
					update_rot_request <= '0';
				 else
					state <= cast_edge_to_32bit;
				 end if;
				 rendered <= '0';
			  end if;

		 end case;
	 end if;
  end process;

end arch;